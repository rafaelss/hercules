task :default => [:test, :doc] do  
end

task :test do  
  require "rubygems"
  require "bundler"
  Bundler.setup
  require "rake/runtest"
  verbose(false) do
    mkdir_p 'tmp'
    File.open('tmp/config.yml', 'w+'){|f| f.write("db1:\n  host: localhost\n  port: 5432\n  database: mailee_test\n  user: mailee\n  password: teste\n") }
    Rake.run_tests 'tests/*test.rb'
  end 
end

task :doc do  
  sh "rdoc src/hercules.rb"
end

