# require 'test_helper'

# # A very basic test just to make sure the batchesworker is functioning properly
# class TestImportBatchesWorker < ActiveSupport::TestCase

#   def test_batch_ingest


#     job = ImportJob.new
#     job.profile = load_fixture('profile.mdl')
#     job.save

#     # # Run the import batch worker syncronously (don't use sidekiq)
#     ImportBatchesWorker.new.perform(job.id, batch_param = nil, perform_async = false)

#     batch = ImportBatch.find(1)

#     # # The response date is variable, so we manually set that to get the test to pass
#     write_fixture('batch_extraction', batch.extraction)
#     batch.extraction.must_equal JSON.parse(load_fixture('batch_extraction.mdl'))

#     # Make sure the enrichments are populated
#     job = ImportJob.find(job.id)
#     job.enrichments.wont_be_nil

#     record = Record.find(1)
#     write_fixture('record_1_metadata', record.metadata)
#     record.metadata.must_equal JSON.parse(load_fixture('record_1_metadata.mdl'))

#     record_count = Record.count
#     record_count.must_equal 15

#     # The test endpoint has 15 records, so we should have 15 revisions
#     versions = PaperTrail::Version.count
#     versions.must_equal 15

#     # Alter the extracted records and reload them to make sure we get new revisions for them
#     batch = ImportBatch.find(1)
#     updated_records = []
#     batch.extraction['records'].each do |record|
#       record['metadata']['dc']['title'] = 'foo'
#       record['metadata']['dc']['contributor'] = 'bar'
#       updated_records << record
#     end
#     batch.extraction['records'] = updated_records
#     batch.extraction_will_change!
#     batch.save!
#     TransformBatchWorker.new.perform(batch.id, false)
#     versions = PaperTrail::Version.count
#     versions.must_equal 20

#     # IF the records haven't changed we should have the same number of version
#     batch.extraction['records'] = updated_records
#     batch.extraction_will_change!
#     batch.save!
#     versions = PaperTrail::Version.count
#     versions.must_equal 20
#   end

#   private
#     # Convert into helpers
#     def load_fixture(name)
#       e = File.open(File.join(File.dirname(__FILE__), "fixtures", "#{name}.json"), 'r')
#       extraction = e.read
#       e.close
#       return extraction
#     end

#     def write_fixture(name, value)
#       filepath = File.join(Rails.root, "tmp", "test", "#{name}.json")
#       File.open(filepath, "w") do |f|
#         f.puts JSON.pretty_generate(value).force_encoding("utf-8")
#     end
#   end
# end

