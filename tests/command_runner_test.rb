# coding: utf-8
require 'src/command_runner'
require 'logger'

class CommandRunnerTest < Test::Unit::TestCase
  def setup
    @log = Logger.new(STDERR)
    @log.level = Logger::ERROR
    @cmd = CommandRunner.new @log
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
end

