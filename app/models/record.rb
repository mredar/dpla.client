require 'json'
require 'digest/sha1'

class Record < ActiveRecord::Base
  include ImportLog
  before_save :live_revision_set, :on => [:create, :update]
  before_save :record_hash_set, :on => [:create, :update]
  belongs_to :transformation_batch
  has_many :record_revisions
  has_one :import_batch, through: :transformation_batch

  around_update :log_update
  after_create :log_create

  validates :record_hash, uniqueness: {
    message: "No two records should share the same record_hash."
  }

  # Log changes to individual records
  def log_update
    metadata_changed = self.changed?
    if metadata_changed
      yield
      import_log.info("Updated Record # #{self.id} for Provider #{self.provider} and Identifier: #{self.identifier}")
    end
  end

  def log_create
      import_log.info("Record Created for #{self.provider} and Identifier: #{self.identifier}.")
  end

  def revisions(identifier, provider)
    Record.where(identifier: @record.identifier, provider: @record.provider)
  end

  def live_revision_set
    # This version has not been designated as being locked as the live revision
    # (e.g. manual edits by app users will trigger this lock so that automated)
    # imports don't automatically override this lock
    if self.lock_as_live_revision == false
      # If this record was previousl locked as the live revision
      # ensure that we don't override that lock with this update.
      if self.changed_attributes['lock_as_live_revision'] == true
        self.is_live_revision = false
      else
        self.is_live_revision = true
      end
    else
      # If no lock on the live revision exists, set this as the new live
      # revision
      self.is_live_revision = true
    end
  end

  def self.hashify(string)
    Digest::SHA1.hexdigest string
  end

  def self.get_record_hash(metadata, identifier, provider)
    begin
      # Only track changes to the transformed doc, not changes in the original record
      self.hashify([metadata.except('originalRecord').to_json, identifier, provider].inject {|field, n| field + n})
      rescue => e
        raise "Could not hashify data for Identifier: `#{identifier}`, Provider: `#{provider}`, Metadata: `#{metadata_string}` Error: #{e}"
      end
  end

  def record_hash_set
    self.record_hash = Record.get_record_hash(self.metadata, self.identifier, self.provider)
  end

  # Compare local record with its counterpart in DPLA
  def diff_with_dpla
    enrichments = self.import_batch.import_job.enrichments
    original_record = self.metadata['originalRecord']
    profile = self.import_batch.import_job.profile.to_json
    pipe = Pipeline.new(profile)
    if !original_record
      return {'error' => "Missing originalRecord metadata, so we can't compare this record with DPLA."}
    end
    transformed = JSON.parse(pipe.transform({'records' => [original_record]}, enrichments))['records'][0]
    if (transformed['isShownAt'])
      compare  = JSON.parse(pipe.compare_with_dpla(transformed, CGI::escape("isShownAt=#{transformed['isShownAt']}")))
      field_diffs = {}
      compare['fields'].each do |key, vals|
        if Diffy::Diff.new(vals[0], vals[1]).to_s(:text) != ""
          field_diffs[key] = self.prettify(vals)
        end
      end
    else
      compare = {'records' => [transformed]}
      field_diffs = []
    end
    {'field_diffs' => field_diffs, 'records' => prettify(compare['records'])}
  end

  protected

    # Generate nice looking JSON for Enumerables
    def prettify(items)
      prettied = []
      items.each do |item|
        if item.is_a?(Enumerable)
          prettied << JSON.pretty_generate(item)
        else
          prettied << item
        end
      end
      prettied
    end
end
