ENV["RAILS_ENV"] ||= "test"
ENV["JWT_AUTH_SECRET"] ||= "123abc"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "webmock/rspec"
require "gds_api/test_helpers/publishing_api"
require "factories"

load Rails.root.join("Rakefile")

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

GovukTest.configure

RSpec.configure do |config|
  if ARGV.empty?
    config.pattern = "{spec,engines/*/spec}/**/*_spec.rb"
  end

  # This allows you to run only failures with --only-failures
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.expose_dsl_globally = false
  config.infer_spec_type_from_file_location!

  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  config.include FactoryBot::Syntax::Methods
  config.include GdsApi::TestHelpers::PublishingApi
  config.include ActiveSupport::Testing::Assertions

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      Timecop.freeze(2011, 11, 11, 11, 11, 11) do
        example.run
      end
    end
  end
end

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

def expect_model_to_be_valid(model:, context: nil)
  expect(model).to be_valid(context), "Expected #{model} in context(#{context}) to be valid."
end

def expect_model_not_to_be_valid(model:, context: nil)
  expect(model).not_to be_valid(context), "Expected #{model} in context(#{context}) NOT to be valid."
end

def expect_elements_to_intersect(array1, array2)
  expect(array1.to_set).to eq(array2.to_set), "Different elements in #{array1.inspect} and #{array2}.inspect"
end

def request_for(path_parameters)
  instance_double(ActionDispatch::Request,
                  path_parameters: path_parameters,
                  env: {})
end
