task :default => [:test, :doc] do  
end

task :test do  
  require "rubygems"
  require "rake/runtest"
  require "bundler"
  Bundler.setup
  verbose(false) do
    mkdir_p 'tmp'
    Rake.run_tests 'tests/*test.rb'
  end 
end

task :doc do  
  sh "cd src && rdoc -o ../doc"
end

