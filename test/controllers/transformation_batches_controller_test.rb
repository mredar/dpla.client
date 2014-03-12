require "test_helper"

describe TransformationBatchesController do
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
    # Now grab a batch with some fake data and associated it with the above job
    @request.env["devise.mapping"] = Devise.mappings[:import_batch]
    @import_batch = FactoryGirl.create(:import_batch)
    @import_batch.import_job_id = @import_job.id
    @import_batch.save!
  end

  after(:each) do
    DatabaseCleaner.clean
  end
end