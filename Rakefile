require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "hercules"
    gem.summary = %Q{TODO: one-line summary of your gem}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email = "diogob@gmail.com"
    gem.homepage = "http://github.com/diogob/hercules"
    gem.authors = ["Diogo Biazus"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :default => [:test, :doc] do
end

desc ":test"
task :test do
  require "rubygems"
  require "rake/runtest"
  require "bundler/setup"
  verbose(false) do
    mkdir_p 'tmp'
    Rake.run_tests 'tests/*test.rb'
  end 
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'tests'
    test.pattern = 'tests/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "hercules_gem #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/*.rb')
end

#TODO group for rake hdi:preview & rake hdi:build
namespace(:hdi) do 
  desc "runs HDI preview"
  task :preview do
    sh "cd hdi && staticmatic preview ."
  end

  desc "build the HDI"
  task :build do
    sh "cd hdi && staticmatic build ."
  end
end
