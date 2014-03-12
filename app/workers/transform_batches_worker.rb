class TransformBatchesWorker
  include ImportLog
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(import_batch_id, perform_async =  true, step = 0)
    transformation_batch, batch, job, pipe = init(import_batch_id, step)
    batch_size = batch.extraction['records'].length

    length = job.profile['transformer']['max_batch_size']
    length ||= 100

    # Transformation processors can take a long time (e.g. geonames), so we
    # allow users to break up transformations into smaller batches to avoid
    # REST call timeouts against the transformer and to run these requests
    # in parallel
    if step == 0
      next_step = step
      batch.extraction['records'].each_slice(length) do |rslice|
        next_step = length + next_step
        if !next_step || next_step == 0 || next_step == ''
          raise
        end
        if next_step < batch.extraction['records'].length
          if (perform_async)
            TransformBatchesWorker.perform_async(import_batch_id, true, next_step)
          else
            TransformBatchesWorker.new.perform(import_batch_id, false, next_step)
          end
        end
      end
    end

    extraction = {}
    extraction['records'] = batch.extraction['records'].slice(step, length)
    import_log.info("TransformationBatchWorker: extracting slice from batch # #{import_batch_id} with slice(#{step},#{length})")
    # fetch a transformation for this slice of recordes
    response = JSON.parse(pipe.transform(extraction, job.enrichments))
    # save a batch of transformed records for loading
    transformation_batch = populate_transformation_batch!(transformation_batch, response, step)

    if perform_async
      LoadRecordsWorker.perform_async(transformation_batch.id)
    else
      LoadRecordsWorker.new.perform(transformation_batch.id)
    end
  end

  def populate_transformation_batch!(transformation_batch, response, step)
    transformation_batch.transformation = response['records']
    transformation_batch.step = step
    transformation_batch.is_active = false
    transformation_batch.save!
    transformation_batch
  end

  # Since we can't pass in the whole job and pipeline to the worker, we
  # initialize it here
  def init(import_batch_id, step)
    import_log.info("TransformAndLoadBatchWorker: init batch #{import_batch_id}")
    batch = ImportBatch.find(import_batch_id)
    transformation_batch = TransformationBatch.find_by(step: step, import_batch_id: import_batch_id)
    transformation_batch ||= TransformationBatch.new(import_batch_id: import_batch_id)
    transformation_batch.is_active = true
    transformation_batch.save
    job = ImportJob.find(batch.import_job_id)
    # The pipeline fetches the batch extraction and enrichment data for us
    pipe = Pipeline.new(job.profile.to_json)
    [transformation_batch, batch, job, pipe]
  end
end