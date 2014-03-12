class ImportBatchesWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true
  include ImportLog


  # Get a profile from a import job, iterate until you run out of next batch
  # paramaters. Enrichments are only processed once.
  def perform(job_id, batch_param = '', async = true, transform = true, recursive = true)

    # Load the job and instantiate the pipeline for communicating with the dpla.service
    job, pipe = init(job_id, batch_param)

    if job.canceled != true

      import_log.info("-------->> ImportBatchesWorker: Processing Batch Parameter `#{batch_param}` for Import Job ##{job.id} <<--------")

      # Populate the batch column for this batch and then return the value
      batch, next_batch_params = populate_batch!(job, pipe, batch_param)

      # Populate the Job enrichment data and/or return it
      enrichments = populate_job_enrichments!(job, pipe)

      if (batch.extraction && transform)
        # The same record can appear in multiple extractions and have different
        # (evolving) values in each extraction (e.g a record is introduced in
        # one extraction batch and then deleted in a subsequent extraction
        # batch). Therefore, we allow profiles to force each extractio to wait
        # for the transformation and loading processes to complete before 
        # proceeding to the next extraction
        if job['profile']['extractor']['allow_concurrent_extractions'] == true
          TransformBatchesWorker.perform_async(batch.id, async)
        else
          TransformBatchesWorker.new.perform(batch.id, async)
        end
      end

      # Recursively call this worker for all provided batch params to allow for
      # concurrent processing of batch extractions
      if recursive
        process_next_batch_params(next_batch_params, job.id, async, transform)
      end
    end
  end

  # Iterate over all remaning baches.
  # Note: we make the sidekiq workers optional to make this method more easily
  # testible
  def process_next_batch_params(next_batch_params, job_id, async = true, transform = true)
    next_batch_params.each do |next_batch_param|
      processed_batch = ImportBatch.where(import_job_id: job_id, batch_param: next_batch_param, processed: true).take
      if processed_batch.nil?
        if (async)
          ImportBatchesWorker.perform_async(job_id, next_batch_param, true, transform)
        else
          ImportBatchesWorker.new.perform(job_id, next_batch_param, false, transform)
        end
      end
    end
  end

  # Since we can't pass in the whole job and pipeline to the worker, we
  # initialize it here
  def init(job_id, batch_params = nil)
    job = ImportJob.find(job_id)
    job.profile['extractor']['records']['batch_params'] ||= []

    if batch_params
      job.profile['extractor']['records']['batch_param'] = batch_params
    end

    # The pipeline fetches the batch extraction and enrichment data for us
    pipe = Pipeline.new(job.profile.to_json)
    [job, pipe]
  end

  # Load or create a new batch and populate it's extraction and batch params
  def populate_batch!(job, pipe, batch_param = nil)
    batch = ImportBatch.find_by(batch_param: batch_param, import_job_id: job.id)
    batch ||= ImportBatch.new

    # Set the Batch
    batch.import_job_id = job.id
    # Mark this batch as "active" until the extraction has been run
    # REFACTOR: how do we test these async features?
    batch.is_active = true
    batch.processed = true
    batch.batch_param = (batch_param == false) ? nil : batch_param
    batch.save!

    extraction = pipe.extraction
    ext = JSON.parse(extraction)
    batch.extraction = extraction
    batch.extraction_will_change!

    batch.is_active = false
    batch.save!

    # On the first batch run, include any default batch params we got from the
    # profile to allow for simultaneous extractions. Useful if the user knows
    # that a particular endpoint has at least n batches worth of data.
    if batch_param == false
      next_batch_params = batch.extraction['next_batch_params'].concat(job.profile['extractor']['records']['batch_params']).flatten.uniq.compact
    else
      next_batch_params = batch.extraction['next_batch_params']
    end
    [batch, next_batch_params]
  end

  # Enrichments are global lookup data made available for each individual
  # record translations. Fetching enrichments is potentially expensive,
  # so we run them once and store them in their own model
  def populate_job_enrichments!(job, pipe)
    if (job.enrichments.nil?)
      job.enrichments = pipe.enrichments
      # Set the original enrichments so that we don't have to fetch them again
      job.save!
      import_log.info("ImportBatchesWorker: Populating #{job.enrichments.count} Enrichments for job #{job.id}")
    end
    job.enrichments
  end
end