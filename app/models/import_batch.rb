class ImportBatch < ActiveRecord::Base
  include ImportLog
  has_many :transformation_batches, dependent: :destroy
  has_many :records, through: :transformation_batches
  belongs_to :import_job

  validates_uniqueness_of :id, scope: :import_job_id


  def transform(perform_async = true)
    if perform_async
      TransformBatchesWorker.perform_async(self.id, perform_async =  true, start = 0)
    else
      TransformBatchesWorker.new.perform(self.id, perform_async =  false, start = 0)
    end
  end
end
