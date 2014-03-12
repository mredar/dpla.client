desc "Add and commit changes, push them to origin"
task :git_push_records do
  git_push_records = File.join(Rails.root, "shared", "git_push_records.sh")

  if (File.exist?(git_push_records))
    unless (system("
      cd #{Rails.root}/shared;
      for dir in */
      do
          dir=${dir%*/}
          (cd ${dir}; ls; git add .; git commit -m 'Endpoint Updates'; git push origin master )
      done
      "))
      STDERR.puts("Script #{git_push_records} returned error condition #{$?}")
    end
  else
    STDERR.puts("Script `#{git_push_records}` not found")
  end
end