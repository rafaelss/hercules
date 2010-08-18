task :default => [:test, :doc] do  
end

task :test do  
  require "rubygems"
  require "bundler"
  Bundler.setup
  require "rake/runtest"
  verbose(false) do
    mkdir_p 'tmp'
    Rake.run_tests 'tests/*test.rb'
  end 
end

task :doc do  
  sh "rdoc src/hercules.rb"
end

