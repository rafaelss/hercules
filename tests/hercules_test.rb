# coding: utf-8
require 'tests/startup'

class HerculesTest < Test::Unit::TestCase
  include Startup

  def test_startup_validations
    verbose(false) do
      # Here we test for config file require
      sh "src/hercules.rb -l /dev/null > /dev/null 2>&1"
      assert !File.exist?(@pidfile)
      
      # Test with an invalid yaml
      sh "src/hercules.rb -c src/hercules.rb -l /dev/null > /dev/null 2>&1" rescue nil
      assert !File.exist?(@pidfile)
    end
  end

  def test_logfile
    start_hercules do |pid,log|
      assert File.exist?(@logfile)
      assert_match /Start/, log
    end
  end

  def test_piddir
    start_hercules do |pid,log|
      assert File.exist?(@pidfile)
      assert_match /\d+/, pid
    end
  end
end
