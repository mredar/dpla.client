class ImportBatchesController < ApplicationController
  before_action :set_import_job, except: [:destroy, :transform]
  before_action :set_import_batch

  # Update an existing batch extraction with a fresh pull from the endpoint
  def extract
    @import_job.extract_batch(@import_batch.batch_param, import_batch_params[:perform_async])
    redirect_to import_job_path(@import_job)
  end

  # Transform and reload records from a batch extraction
  def transform
    @import_batch.transform(import_batch_params[:perform_async])
    redirect_to root_path
  end

  def destroy
    @import_batch.destroy
    redirect_to root_path
  end

  def download_transformations
    transformations = []
    @import_batch.transformation_batches.each do |t_batch|
      transformations = transformations.concat(t_batch.transformation)
    end
    send_data JSON.pretty_generate(transformations), :type => 'application/json', filename: "job-#{@import_job.id}-batch-#{@import_batch.id}.json"
  end

  private

    def set_import_batch
      @import_batch = ImportBatch.find(params[:id])
    end

    def set_import_job
      @import_job = ImportJob.find(import_batch_params[:import_job_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def import_batch_params
      params.require(:import_batch).permit(:perform_async, :page, :import_job_id)
    end
end
