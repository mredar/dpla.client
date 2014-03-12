source 'http://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.1'

# Use sqlite3 as the database for Active Record
gem 'pg'

# Use SCSS for stylesheets
# gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'iconv'
gem 'actionpack-action_caching'
gem 'dotenv-rails', :groups => [:development, :test]
gem 'brakeman', :require => false
gem 'rails_best_practices'
gem 'deep_merge'
gem 'sass-rails', '>= 3.2' # sass-rails needs to be higher than 3.2
gem 'bootstrap-sass', '~> 3.0.3.0'
gem "less-rails"
gem 'attempt'
gem 'sidekiq'
gem 'sinatra', require: false
gem 'slim'
gem 'rest-client'
gem 'devise'
gem 'will_paginate', '~> 3.0'
gem 'diffy'

group :test, :development do
  # Debug seems to have trouble w/ Ruby 2.x, byebug is a replacment
  gem 'byebug'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'coderay', '~> 1.0.5'
  gem 'guard-minitest'
  gem "minitest-rails"
  gem "minitest-rails-capybara"
  gem 'turn'
  # Ensure database is cleaned between tests
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails'
  gem 'ruby-prof'
  gem 'zeus'
  # Quite logs down by removing asset requests
  gem 'quiet_assets'
end