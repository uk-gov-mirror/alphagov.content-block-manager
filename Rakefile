# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
Rails.application.load_tasks

unless Rails.env.production?
  require "cucumber/rake/task"
  require "rspec/core/rake_task"

  # We only set this var when running via Rake, so that we can get
  # sensible coverage reports when running a full test suite,
  # without overwriting them when we're just running a single test
  ENV["COVERAGE"] = "true"

  RSpec::Core::RakeTask.new(:spec)

  Cucumber::Rake::Task.new(:cucumber) do |t|
    t.cucumber_opts = ["--format pretty"]
  end

  Rake::Task[:default].clear if Rake::Task.task_defined?(:default)
  task default: %i[lint test spec cucumber]
end
