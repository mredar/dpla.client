# This will guess the User class
FactoryGirl.define do
  factory :user do
    email "foo@example.com"
    password "kittehzrule"
    authorization_level 0
  end

  factory :admin, class: User do
    email "foo1@example.com"
    password "kittehzrule1"
    authorization_level 1
  end

  factory :import_job do
    profile File.read(File.join(Rails.root, "test", "fixtures", "profile.json"))
  end

  factory :import_batch do
    extraction File.read(File.join(Rails.root, "test", "fixtures", "batch_extraction.json"))
  end

  factory :transformation_batch do
    transformation File.read(File.join(Rails.root, "test", "fixtures", "batch_transformation.json"))
  end
end