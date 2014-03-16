require "test_helper"

describe ImportBatchesController do
  include Devise::TestHelpers

  before(:each) do |item|
    # Strong arm clean the test environment
    DatabaseCleaner.start
    # Log in as an admin
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:admin)

    # Create a default import job
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)

    # Gin up a batch with factory girl
    @request.env["devise.mapping"] = Devise.mappings[:import_batch]
    @import_batch = FactoryGirl.create(:import_batch)

    @import_batch.import_job_id = @import_job.id
    @import_batch.save!
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it "should reextract a batch's data" do
    # make a little change to the extractio so that we can verify later that
    # reextraction actually took plas
    @import_batch.extraction['testfield'] = 'test'
    # In-place edits to certain fields, like JSON need to be manually marked
    # as dirty
    @import_batch.extraction_will_change!
    @import_batch.save!
    @import_batch = ImportBatch.find(@import_batch.id)
    refute_nil @import_batch.extraction['testfield']
    refute_nil @import_batch.import_job_id
    resp = post :extract, import_batch: { perform_async: false, import_job_id: @import_job.id }, id: @import_batch.id
    # Verify that the batch was actually overritten
    @import_batch = ImportBatch.find(@import_batch.id)
    @import_batch.extraction['testfield']
    # Ensure that the job enrichments are populated
    @import_job = ImportJob.find(@import_job.id)
    refute_nil @import_job.enrichments
  end

  it "should destroy a batch and its related transformations and records" do
    @transformation_batch = @import_batch.transformation_batches.create()
    @records = @transformation_batch.records.create(identifier: 'foo', provider: 'bar', metadata: {"foo" => "bar"})
    assert_equal 1, Record.all.count
    assert_equal 1, ImportBatch.count
    assert_equal 1, TransformationBatch.count
    delete :destroy, id: @import_batch
    # Verify that the batch was actually destroyed
    assert_equal 0, ImportBatch.count
    # Verify that the transformation batch was actually destroyed
    assert_equal 0, TransformationBatch.count
    # Verify that the transformation batch records have been deleted
    assert_equal 0, Record.all.count
  end

  it "should transform and retransform its extraction data" do
    post :transform, import_batch: { perform_async: false}, id: @import_batch.id
    @transformation_batch = TransformationBatch.take(1)[0]
    refute_nil @transformation_batch.transformation
    refute_nil @transformation_batch.import_batch_id
    assert_equal 2, TransformationBatch.count
    assert_equal 5, Record.all.count

    # Now alter the extraction and make sure the record gets updated
    @import_batch.extraction['records'][0]['metadata']['dc']['title'] = 'Foo bar baz'
    @import_batch.extraction['records'][1]['metadata']['dc']['title'] = 'Baz bar foo'
    @import_batch.extraction_will_change!
    @import_batch.save
    post :transform, import_batch: { perform_async: false}, id: @import_batch.id
    # Run the transformation again to ensure idempotence
    # post :transform, import_batch: { perform_async: false}, id: @import_batch.id

    # We should still have 5 records
    assert_equal 5, Record.all.count

    # Make sure the metadata gets revised
    record_1 = Record.where(identifier: @import_batch.extraction['records'][1]['header']['identifier']).take
    record_2 = Record.where(identifier: @import_batch.extraction['records'][1]['header']['identifier']).take
    assert_equal 2,  record_1.metadata['revisions'].count
    assert_equal 2,  record_2.metadata['revisions'].count

    # OK, let's make sure the live revision is from our last update
    assert_equal 'Baz bar foo', record_1.metadata_live['title']

  end

  it "should download transformed JSON files for a given batch" do
    post :transform, import_batch: { perform_async: false}, id: @import_batch.id
    response = post :download_transformations, import_batch: { import_job_id: @import_job.id}, id: @import_batch.id
    assert_equal response.content_type, "application/json"
    assert_equal response.success?, true
  end
end
