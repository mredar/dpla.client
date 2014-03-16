class LoadRecordsWorker
  include ImportLog
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(transform_batch_id)
    t_batch = TransformationBatch.find(transform_batch_id)
    t_batch.is_active = true
    t_batch.save
    import_log.info("LoadRecordsWorker: Starting Loading Process for tranformation batch ##{transform_batch_id} with `#{t_batch.transformation.count}` records transformed.")

    # Get records for upsert
    upserts = prepare_upserts(t_batch.transformation, t_batch.id)

    # Order Matters after this point: First Update records that can be updated
    # then add new records where they don't already exist
    # 1 Update records, return records for creation
    inserts = update_records(upserts)

    # For any records that didn't already exist:
    # 2 Create new records
    create_records(inserts)

    t_batch.is_active = false
    t_batch.save
  end

  def create_records(records)
    if (!records.empty?)
      inserts = []
      records.each do |record_hash, value|
        inserts << value
      end
      begin
        import_log.info("LoadRecordsWorker: Attempting to create #{inserts.count} new records.")
        created = Record.create(inserts)
      rescue => e
        import_log.error("LoadRecordsWorker: Failed to create records. Error Message: #{e.message}")
        raise e
      end
    end
  end

  # Attempt to update records that already exists, return records that don't
  # Note: it may be desirable for performance reasons in the long run to switch
  # to the upsert gem (https://github.com/seamusabshere/upsert) or use a similar
  # approach
  def update_records(upserts)
    updatables = Record.select('id, record_hash, identifier, provider').where('record_hash IN (?)', upserts.keys)
    updates = {}
    updatables.each do |up|
      updates[up.record_hash] = upserts[up.record_hash]
      upserts.delete(up.record_hash)
    end
    if (!updates.empty?)
      begin
        updated = Record.update(updates.keys, updates.values)
      rescue => e
        import_log.error("Failed to update records #{updates.keys}. Error Message: #{e.message}")
        raise e
      end

    end
    upserts
  end

  # Generate an array of hashes for insert or update, keyed by record
  # identifiers.
  def prepare_upserts(records, t_batch_id)
    upserts = {}
    records.each do |r|
      # Create a new record to get a record hash
      record = Record.new(:provider => r['provider']['@id'], :identifier => r['identifier'])
      begin
        upserts[record.record_hash] = {
          :title => r['title'],
          :identifier => r['identifier'],
          :provider => r['provider']['@id'],
          :metadata => r,
          :is_published => 'f',
          :transformation_batch_id => t_batch_id
        }
      rescue => e
        import_log.error("Could manage to create an upsert for record #{r} got error: #{e.message}")
        raise e
      end
    end
    upserts
  end
end