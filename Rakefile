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

desc ":doc"
task :doc do
  sh "rm -rf doc"
  sh "cd src && rdoc -o ../doc"
end

#TODO group for rake hdi:preview & rake hdi:build

desc "runs HDI preview"
task :preview do
  sh "cd src/webinterface/hdi && staticmatic preview ."
end

desc "build the HDI"
task :build do
  sh "cd src/webinterface/hdi && staticmatic build ."
end
