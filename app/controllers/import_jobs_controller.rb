require 'fileutils'

class ImportJobsController < ApplicationController
  before_action :set_import_job, except: [:index, :new, :create, :share_job, :show]

  # GET /import_jobs
  # GET /import_jobs.json
  def index
    @import_jobs = ImportJob.all
  end

  # GET /import_jobs/1
  # GET /import_jobs/1.json
  def show
    @import_job = ImportJob.where(id: params[:id]).select("id, canceled, notes, name, profile").take
    @is_active = @import_job.has_active_batches?
    @import_batches = ImportBatch.where(import_job_id: params[:id])
      .select('import_batches.id, batch_errors, batch_param, is_active').order(id: :asc)
  end

  # GET /import_jobs/new
  def new
    @import_job = ImportJob.new
  end

  # GET /import_jobs/1/edit
  def edit
    @import_job.profile = JSON.pretty_generate(@import_job.profile)
  end

  # POST /import_jobs
  # POST /import_jobs.json
  def create
    @import_job = ImportJob.new(import_job_params)
    respond_to do |format|
      if @import_job.save
        format.html { redirect_to @import_job, notice: 'Import job was successfully created.' }
        format.json { render action: 'show', status: :created, location: @import_job }
      else
        format.html { render action: 'new' }
        format.json { render json: @import_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /import_jobs/1
  # PATCH/PUT /import_jobs/1.json
  def update
    respond_to do |format|
      if @import_job.update(import_job_params)
        format.html { redirect_to @import_job, notice: 'Import job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @import_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /import_jobs/1
  # DELETE /import_jobs/1.json
  def destroy
    @import_job.destroy
    respond_to do |format|
      format.html { redirect_to import_jobs_url }
      format.json { head :no_content }
    end
  end

  # DELETE /import_jobs/1
  # DELETE /import_jobs/1.json
  def destroy_batches
    @import_job.import_batches.each do |batch|
      batch.destroy
    end
    redirect_to @import_job, notice: "Batches and related records for this job have been destroyed."
  end

  def run_workers
    # Extract all batches and conditionally transform into records and load
    # records into the database
    @import_job.run_workers(import_job_params[:perform_async], import_job_params[:transform_load])
    redirect_to @import_job, notice: "Running ETL for Import Job # #{@import_job.id}"
  end

  def run_worker
    # Extract one batch and conditionally transform into records and load
    # records into the database
    @import_job.run_worker(import_job_params[:perform_async], import_job_params[:transform_load], import_job_params[:batch_param])
    redirect_to @import_job, notice: "Running ETL for the batch with param #{import_job_params[:batch_param]}` of Import Job # #{@import_job.id}"
  end

  def cancel
    @import_job.update(canceled: true)
    redirect_to import_jobs_path, notice: "Import Job # #{@import_job.id} scheduled to stop after processing the current batch."
  end

  def share_job
    job = ImportJob.find(params[:id])
    job.import_batches.each do |import_batch|
      FileUtils.mkdir_p File.join(Rails.root, "shared", "#{job.name}")
      records = []
      import_batch.transformation_batches.each do |t_batch|
        t_batch.records.each do |record|
          records << record.metadata_live
        end
      end
      share_records(File.join(Rails.root, "shared", "#{job.name}", "batch-#{import_batch.id}-records.json"), records)
    end

    redirect_to import_jobs_path
  end

  def share_records(filepath, records)
    File.open(filepath, "w") do |f|
      f.puts records.to_json.force_encoding("utf-8")
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_import_job
      @import_job = ImportJob.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def import_job_params
      params.require(:import_job).permit(:status, :notes, :profile, :perform_async, :transform_load, :name, :batch_param)
    end
end
