# coding: utf-8
require 'git'

class GitHandler
  def initialize(options)
    @options = options
  end

  def export_branch(branch = 'master')
    tmp_dir = "#{@options['target_directory']}/checkouts/#{branch}/.tmp"
    repo = Git.clone(@options['repository'], tmp_dir, {:depth => 1})
    repo.checkout("origin/#{branch}")
    commit_dir = "#{@options['target_directory']}/checkouts/#{branch}/#{repo.gcommit('HEAD').sha}"
    Dir.chdir(repo.dir.to_s) { FileUtils.rm_r '.git' }
    FileUtils.mv repo.dir.to_s, commit_dir
    commit_dir
  end

  def branches_path
    "#{@options['target_directory']}/branches"
  end

  def create_branches_dir
    FileUtils.mkdir_p branches_path
    branches_path
  end

  def deploy_branch(branch = 'master')
    FileUtils.ln_sf(export_branch(branch), "#{create_branches_dir}/#{branch}")
    self
  end
end
