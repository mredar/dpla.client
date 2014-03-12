module RecordHelper
  def live_revision(batch_id, updated_at, live_rev)
    (batch_id == live_rev.import_batch_id && updated_at == live_rev.updated_at) ? '(Live Revision)' : nil
  end
end
