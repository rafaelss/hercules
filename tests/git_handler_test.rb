# coding: utf-8
require 'git'
require 'src/git_handler'
require 'tests/git_setup'

class GitHandlerTest < Test::Unit::TestCase
  include GitSetup
  def setup
    git_setup
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

