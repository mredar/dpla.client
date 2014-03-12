json.array!(@import_jobs) do |import_job|
  json.extract! import_job, :schedule, :status, :notes
  json.url import_job_url(import_job, format: :json)
end
