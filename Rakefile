#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

unless ENV['RAILS_ENV'] == 'production'
  require File.expand_path('../config/application', __FILE__)
  require 'rubocop/rake_task'
end

RuboCop::RakeTask.new
Brandscopic::Application.load_tasks
