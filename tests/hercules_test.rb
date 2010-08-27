# coding: utf-8
require 'tests/startup'

class HerculesTest < Test::Unit::TestCase
  include Startup

  def setup
    prepare_startup
  end

  def test_startup_validations
    verbose(false) do
      # Here we test for config file require
      sh "src/hercules.rb -l /dev/null > /dev/null 2>&1"
      sleep 1
      assert !File.exist?(@pidfile)
      
      # Test with an invalid  yaml
      sh "src/hercules.rb -c src/hercules.rb -l /dev/null > /dev/null 2>&1" rescue nil
      sleep 1
      assert !File.exist?(@pidfile)
    end
  end

  def test_logfile_and_piddir
    start_hercules do |pid,log|
      assert File.exist?(@logfile)
      assert_match /Start/, log.read()
      assert File.exist?(@pidfile)
      assert_match /\d+/, pid
    end
  end

  def test_send_term
    start_hercules do |pid,log|
      Process.kill("TERM", pid.to_i)
      sleep 1
      assert !File.exist?(@pidfile)
      assert_match /Terminating hercules/, log.read
    end
  end
end
