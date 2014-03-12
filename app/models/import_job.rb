class ImportJob < ActiveRecord::Base
  include ImportLog
  has_many :import_batches, dependent: :destroy
  has_many :transformation_batches, through: :import_batches

  def has_active_batches?
    if ImportBatch.select("id").where("import_job_id = ? AND is_active = true", self.id).take
      return true
    elsif TransformationBatch.select("transformation_batches.id").joins(:import_batch).where("import_batches.import_job_id = ? AND transformation_batches.is_active = true", self.id).take
      return true
    end
    false
  end

  # Re-extract all batches for a given import_job
  #
  # NOTE: this method has been placed in the import job model because
  # import batches are children of import jobs. The ImportBatchesWorker
  # creates and/or updates all/some import batches for a given import job
  def run_workers(async = true, transform = false)
    # Tell the import job to forget about the batches it has already run
    # so that it will not prevent these batches from being reextracted
    reset_all_batches
    extract!(batch_param = nil, async, transform, recursive = true)
  end

  def run_worker(async = true, transform = false, batch_param = nil)
    reset_one_batch(batch_param)
    extract!(batch_param = nil, async, transform, recursive = false)
  end

  def reset_all_batches
    # Allow batches to re reprocessed
    self.import_batches.each do |batch|
      batch.processed = false
      batch.is_active = false
      batch.save
    end
    self.enrichments = nil
    self.save!
  end

  def reset_one_batch(batch_param)
    batch = ImportBatch.where(batch_param: batch_param, import_job_id: self.id).take
    if batch
      batch.processed = false
      batch.is_active = false
      batch.save
      self.enrichments = nil
      self.save!
    end
  end

  # Extract a single batch (pre-existing or new import batch)
  def extract_batch(batch_param = nil, async = true)
    reset_one_batch(batch_param)
    # A batch for a given import job is extracted based on its batch_param
    extract!(batch_param, async, transform  = false, recursive = false)
  end

  def extract!(batch_param = nil, async = true, transform = false, recursive = false)
    if async
      ImportBatchesWorker.perform_async(self.id, batch_param, async = true, transform, recursive)
    else
      ImportBatchesWorker.new.perform(self.id, batch_param, async = false, transform, recursive)
    end
  end
end
