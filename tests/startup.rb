# coding: utf-8

# Test mailer startup reading a YAML file and requesting config info
module Startup
  def prepare_startup
    @logfile = 'tmp/test.log'
    @pidfile = 'hercules.pid'
  end

  def cleanup
    File.unlink @logfile if File.exist?(@logfile)
    File.unlink @pidfile if File.exist?(@pidfile)
  end

  def start_hercules config = 'tests/fixtures/config.yml'
    verbose(false) do
      Bundler.with_clean_env do
        sh "bin/hercules -l tmp/test.log -V -c " + config
      end
      begin
        sleep 1
        pid = File.open(@pidfile, 'r').read()
        log = File.open(@logfile, 'r')
        yield(pid, log)
        sh "kill -KILL #{pid} >/dev/null 2>&1" rescue nil
        sleep 1
        assert !File.exist?('tmp/hercules.pid'), "PID file still exists after daemon shutdown"
      ensure
        # just to make sure we always kill the test instances
        sh "kill -KILL #{pid} >/dev/null 2>&1" rescue nil
        cleanup
      end
    end
  end
end

