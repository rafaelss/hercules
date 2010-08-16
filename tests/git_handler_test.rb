# coding: utf-8
require 'git'
require 'src/git_handler'

class GitHandlerTest < Test::Unit::TestCase
  def setup
    @config = YAML.load_file(File.dirname(__FILE__) + '/fixtures/config.yml')
    dir = @config['test_project']['repository'].gsub(/file:\/\//, '')
    FileUtils.rm_rf(dir)
    FileUtils.rm_rf(@config['test_project']['test']['target_directory'])
    FileUtils.mkdir_p(dir)
    FileUtils.cp(File.dirname(__FILE__) + '/fixtures/config.yml', "#{dir}/config.yml")
    g = Git.init(dir)
    g.chdir do
      g.config('user.name', 'Test User')
      g.config('user.email', 'email@email.com')
      g.add("./config.yml")
      g.commit_all('message')
    end
  end

  def test_checkout_to_directory
    g = GitHandler.new(@config['test_project'])
    g.checkout_to_directory('test')
    assert_equal File.open(File.dirname(__FILE__) + '/fixtures/config.yml').read, File.open(@config['test_project']['test']['target_directory'] + '/config.yml').read
    assert !File.exists?(@config['test_project']['test']['target_directory'] + '/.git')
  end
end

