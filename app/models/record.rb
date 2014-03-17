require 'json'
require 'digest/sha1'

class Record < ActiveRecord::Base
  include ImportLog
  self.primary_key = "record_hash"
  belongs_to :transformation_batch
  has_many :record_revisions
  has_one :import_batch, through: :transformation_batch
  has_many :metadata_records, autosave: true
  around_update :log_update
  after_create :log_create

  validates :record_hash, uniqueness: {
    message: "No two records should share the same record_hash."
  }

  # A method to fetch the live revision of the metadata
  def metadata_live
    if hash_lock = self.lock_at_metadata_hash
      return has_revision?(self.metadata['revisions'], hash_lock)
    else
      # Get the last version, discard the hash key, return the value
      return self.metadata['revisions'].pop.values.pop
    end
  end

  # Custom metadata setter to allow for revision retrieval by metadata hash key
  # This value will be appended to any previously saved values
  def metadata=(value)
    if (defined?(self[:metadata]['revisions']))
      self[:metadata]['revisions'] << {metadata_hash(value) => value}
      self[:metadata]['revisions'].uniq!
      # In-place edits to
      self.metadata_will_change!
    else
      self[:metadata] = {'revisions' => [{metadata_hash(value) => value}]}
    end
  end

  def record_hash
    if self.attribute_present?(:provider) && self.attribute_present?(:identifier)
      return self[:record_hash] = hashify("#{self.provider}#{self.identifier}")
    else
      raise "Both the Provider and Identifier MUST BE SET in order to access the record_hash."
    end
  end

  def record_hash=
    raise "Record hash cannot be directly set"
  end

  def has_revision?(revisions, revision_hash)
    revisions ||= []
    revisions.reduce(nil) {|memo, revision| revision[revision_hash] ? revision[revision_hash] : memo}
  end

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

  # Generate a hash of the transformed metadata
  def metadata_hash(metadata)
    hashify(metadata.except('originalRecord').to_json)
  end

  def hashify(string)
    Digest::SHA1.hexdigest string
  end

  # Compare local record with its counterpart in DPLA
  def diff_with_dpla
    enrichments = self.import_batch.import_job.enrichments
    original_record = self.metadata_live['originalRecord']
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
