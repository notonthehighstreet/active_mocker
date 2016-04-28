# frozen_string_literal: true
require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"
Dir.glob("tasks/*.rake").each { |r| import r }

task default: "specs"

task :specs do
  Rake::Task["setup"].invoke
  Rake::Task["unit"].invoke
  Rake::Task["integration"].invoke
end

task :test do
  Rake::Task["unit"].invoke
  Rake::Task["integration"].invoke
end
