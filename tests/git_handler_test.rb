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

  def test_should_deploy_test_branch
    @g.branch('test').checkout
    g = GitHandler.new(@config['test_project'])
    g.deploy_branch('test')
    assert_is_checkout @config['test_project']['target_directory'] + '/branches/test'
  end

  def test_should_maintain_at_most_three_test_checkouts
    @g.branch('test').checkout
    g = GitHandler.new(@config['test_project'])
    4.times do |t|
      generate_commit "new_commit#{t}"
      g.deploy_branch('test')
      assert File.exists?(@config['test_project']['target_directory'] + "/branches/test/new_commit#{t}")
      # The checkouts_to_keep in config.yml is set to 3 (so 5 is the maximum: 3 + '.' + '..')
      assert_equal (3+t > 5 ? 5 : 3+t), Dir.entries(@config['test_project']['target_directory'] + '/checkouts/test').size
      sleep 1
    end
  end

  def test_should_maintain_only_one_master_checkout
    g = GitHandler.new(@config['test_project'])
    g.deploy_branch('master')
    sleep 1
    generate_commit 'new_commit'
    g.deploy_branch('master')
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master/new_commit')
    assert_equal 3, Dir.entries(@config['test_project']['target_directory'] + '/checkouts/master').size
  end

end

