# coding: utf-8
require 'src/command_runner'
require 'logger'
require 'test/unit'

class CommandRunnerTest < Test::Unit::TestCase
  def setup
    @log = Logger.new(STDERR)
    @log.level = Logger::ERROR
    @cmd = Hercules::CommandRunner.new @log
  end

  def test_command_output
    assert_equal 'test', @cmd.run("echo test").output
  end

  def test_command_log
    @cmd.run("echo test1")
    @cmd.run("echo test2")
    @cmd.run("echo test3")
    assert_equal "test1\ntest2\ntest3\n", @cmd.output
  end

  def test_command_log_store
    @cmd.run("echo test1")
    @cmd.run("echo test2")
    @cmd.run("echo test3")
    file = "/tmp/output.#{Time.now.strftime "%Y%m%d%H%M%S"}.log"
    @cmd.store_output file
    File.open(file, 'r') do |f|
      assert_equal "test1\ntest2\ntest3\n", f.read
    end
  end
end

