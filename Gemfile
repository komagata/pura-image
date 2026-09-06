source "https://rubygems.org"

gemspec

gem "rubocop", require: false
gem "erb", require: false # RuboCop configuration templates on Ruby distributions without default ERB

# Optional dependencies for the real Active Storage integration job.
if ENV["RAILS_VERSION"]
  gem "activestorage", ENV.fetch("RAILS_VERSION")
  gem "railties", ENV.fetch("RAILS_VERSION")
  gem "sqlite3", "~> 2.1"
end
