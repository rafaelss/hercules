# coding: utf-8
require 'git'
require 'src/git_handler'

class GitHandlerTest < Test::Unit::TestCase
  def setup
    @config = YAML.load_file(File.dirname(__FILE__) + '/fixtures/config.yml')
    dir = @config['test_project']['repository'].gsub(/file:\/\//, '')
    FileUtils.rm_rf(dir)
    FileUtils.rm_rf(@config['test_project']['target_directory'])
    FileUtils.mkdir_p(dir)
    FileUtils.cp(File.dirname(__FILE__) + '/fixtures/config.yml', "#{dir}/config.yml")
    g = Git.init(dir)
    g.chdir do
      g.config('user.name', 'Test User')
      g.config('user.email', 'email@email.com')
      g.add("./config.yml")
      g.commit_all('message')
      @head_sha = g.gcommit('HEAD').sha
    end
  end

  def assert_is_checkout(dir)
    assert_equal File.open(File.dirname(__FILE__) + '/fixtures/config.yml').read, File.open(dir + '/config.yml').read
    assert !File.exists?(dir + '/.git')
  end

  def test_export_branch
    g = GitHandler.new(@config['test_project'])
    g.export_branch('master')
    assert_is_checkout @config['test_project']['target_directory'] + '/checkouts/master/' + @head_sha
  end

  def test_create_environments_dir
    g = GitHandler.new(@config['test_project'])
    g.create_environments_dir
    assert File.exists? @config['test_project']['target_directory'] + '/environments'
  end

  def test_environments_dir
    g = GitHandler.new(@config['test_project'])
    assert_equal @config['test_project']['target_directory'] + '/environments', g.environments_path
  end

  def test_deploy_branch
    g = GitHandler.new(@config['test_project'])
    g.deploy_branch('master')
    assert_is_checkout @config['test_project']['target_directory'] + '/environments/master'
  end
end

