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
      sh "src/hercules.rb -l /dev/null > /dev/null 2>&1" rescue nil
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

  def test_send_hup
    start_hercules do |pid,log|
      Process.kill("HUP", pid.to_i)
      sleep 1
      assert File.exist?(@pidfile)
      log_content = log.read
      assert_match /Reloading config/, log_content
      assert_no_match /Error reading/, log_content
    end
  end

  def test_send_hup_with_bad_config_file
    start_hercules do |pid,log|
      FileUtils.mv "tests/fixtures/config.yml", "tests/fixtures/config.old.yml"
      FileUtils.mv "tests/fixtures/bogus_config.yml", "tests/fixtures/config.yml"
      Process.kill("HUP", pid.to_i)
      sleep 1
      assert File.exist?(@pidfile)
      log_content = log.read
      FileUtils.mv "tests/fixtures/config.yml", "tests/fixtures/bogus_config.yml"
      FileUtils.mv "tests/fixtures/config.old.yml", "tests/fixtures/config.yml"
      assert_match /Reloading config/, log_content
      assert_match /Error reading/, log_content
    end
  end
end
