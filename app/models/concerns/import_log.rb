module ImportLog

  def import_log
    if Rails.env.test?
      @@import_log ||= Logger.new("#{Rails.root}/log/import-test.log")
    elsif Rails.env.development? || Rails.env.production?
      @@import_log ||= Logger.new("#{Rails.root}/log/import.log")
    end
  end
end