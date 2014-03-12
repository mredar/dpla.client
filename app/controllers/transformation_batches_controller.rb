class TransformationBatchesController < ApplicationController

  # Show a bunch of records associated
  def import_batch_records
    @import_batch = ImportBatch.includes(:records).find(transform_batch_params[:import_batch_id])
    @import_job = ImportJob.find(@import_batch.import_job_id)
    @records = []
    @import_batch.records.each do |record|
      @records << record
    end
  end

 private

    # Never trust parameters from the scary internet, only allow the white list through.
    def transform_batch_params
      params.permit(:perform_async, :import_batch_id)
    end
end
