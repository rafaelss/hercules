# coding: utf-8

# Test mailer startup reading a YAML file and requesting config info
class StartupTest < Test::Unit::TestCase
  def setup
    @config = YAML.load_file( 'tmp/config.yml' ) 
    @logfile = 'tmp/test.log'
    @pidfile = 'hercules.pid'
  end

  def cleanup
    File.unlink @logfile if File.exist?(@logfile)
    File.unlink @pidfile if File.exist?(@pidfile)
  end

  def start_hercules
    verbose(false) do
      sh "src/hercules.rb -l tmp/test.log -V -c tmp/config.yml"
      begin
        sleep 3
        pid = File.open(@pidfile, 'r').read()
        log = File.open(@logfile, 'r').read()
        yield(pid, log)
        sh "kill #{pid}"
        sleep 1
        assert !File.exist?('tmp/hercules.pid'), "PID file still exists after daemon shutdown"
      ensure
        # just to make sure we always kill the test instances
        sh "kill #{pid} >/dev/null 2>&1" rescue nil
        cleanup
      end
    end
  end

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

