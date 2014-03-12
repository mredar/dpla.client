require "test_helper"

class UserTest < ActiveSupport::TestCase

  before(:each) do |item|
    # Strong arm clean the test environment
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  def test_valid
    user = User.new
    user.email = 'foozzz@example.com'
    user.password = 'blergsdfsdf'
    user.save
    assert user.valid?, "Can't create with valid params: #{user.errors.messages}"
  end

  def test_invalid_without_email
    user = User.new
    user.email = ''
    user.password = 'blergsdfsdf'
    assert !user.save, "Can't be valid without email"
  end
end