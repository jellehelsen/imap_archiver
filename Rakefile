require 'rubygems'
require 'rake'
require "bundler"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "imap_archiver"
    gem.summary = %Q{Tool to archive lots of messages in an imap server}
    gem.description = %Q{imap_archiver is a command line tool to archive messages on an imap server. 
      You tell it what folders to archive and where to archive it.
      For every folder that is archived a series of folders (one for each month) is created inside the archive folder.}
    gem.email = "jelle.helsen@hcode.be"
    gem.homepage = "http://github.com/jellehelsen/imap_archiver"
    gem.authors = ["Jelle Helsen"]
    gem.add_bundler_dependencies
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

# Spec::Rake::SpecTask.new(:rcov) do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.pattern = 'spec/**/*_spec.rb'
#   spec.rcov = true
# end

# task :spec => :check_dependencies

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "imap_archiver #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
