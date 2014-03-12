require "test_helper"

describe ImportJobsController do
  include Devise::TestHelpers

  before(:each) do |item|
    DatabaseCleaner.start
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:admin)
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it "must show the import jobs index page to authorized users" do
    get :index
    assert_response :success
  end

  it "should get a new factory page" do
    get :new
    assert_response :success
  end

  it "should create import_job" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    import_job = build_stubbed(:import_job)
    post :create, import_job: { profile: import_job.profile }
    assert_equal 1, ImportJob.count
    assert_redirected_to import_job_path(assigns(:import_job))
  end

  it "should show import_job" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)
    get :show, id: @import_job
    assert_response :success
  end

  it "should get edit" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)
    get :edit, id: @import_job
    assert_response :success
  end

  it "should update import_job" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)
    @import_job.profile = {}.to_json
    patch :update, id: @import_job, import_job: { profile: @import_job.profile  }
    assert_redirected_to import_job_path(assigns(:import_job))
  end

  it "should destroy import_job" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)
    delete :destroy, id: @import_job
    assert_equal 0, ImportJob.count
    assert_redirected_to import_jobs_path
  end

  it "should run the import job and create import_batches based on the test profile" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)
    post :run_workers, import_job: {perform_async: false, transform_load: false }, id: @import_job.id
    assert_equal 3, ImportBatch.count

    # REFACTOR:
    # This is a little side-effecty, but enrichments are loaded into imort jobs
    # exactly once, on the first run of the first batch import. Perhaps this
    # this should happen as a seperate step, but I am leaving that as a task
    # for another day
    @import_job = ImportJob.find(@import_job.id)
    refute_nil @import_job.enrichments

    ImportBatch.all.each do |batch|
      refute_nil batch.extraction
      assert_equal @import_job.id, batch.import_job_id
    end
  end

  it "should run and create only the first import batch" do
    @request.env["devise.mapping"] = Devise.mappings[:import_job]
    @import_job = FactoryGirl.create(:import_job)
    post :run_worker, import_job: {perform_async: false, transform_load: false }, id: @import_job.id
    assert_equal 1, ImportBatch.count
  end
end