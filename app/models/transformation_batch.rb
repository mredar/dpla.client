class TransformationBatch < ActiveRecord::Base
  include ImportLog
  # Because there can be many records, we wrap the destroy hook in a worker
  belongs_to :import_batch
  has_many :records, dependent: :destroy
  has_one :import_job, through: :import_bach
end