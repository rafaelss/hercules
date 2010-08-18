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

  def test_create_branches_dir
    g = GitHandler.new(@config['test_project'])
    g.create_branches_dir
    assert File.exists? @config['test_project']['target_directory'] + '/branches'
  end

  def test_branches_dir
    g = GitHandler.new(@config['test_project'])
    assert_equal @config['test_project']['target_directory'] + '/branches', g.branches_path
  end

  def test_deploy_branch
    g = GitHandler.new(@config['test_project'])
    g.deploy_branch('master')
    assert_is_checkout @config['test_project']['target_directory'] + '/branches/master'
  end

end

