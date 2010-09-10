# coding: utf-8
require 'git'

module Hercules
  class GitHandler
    def initialize(options)
      @options = options
    end

    def export_branch(branch = 'master')
      tmp_dir = "#{@options['target_directory']}/checkouts/#{branch}/.tmp_#{Time.now.strftime("%Y%m%d%H%M%S")}"
      begin
        repo = Git.clone(@options['repository'], tmp_dir, {:depth => 1})
        repo.checkout("origin/#{branch}")
      rescue Exception => e
        FileUtils.rm_rf repo.dir.to_s unless repo.nil?
        raise "Error while cloning #{@options['repository']}: #{e}"
      end
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
      checkout = export_branch(branch)
      #@todo here we must call the before deploy script
      yield(checkout, branch) if block_given?
      remove_old_checkouts branch
      FileUtils.rm_f("#{create_branches_dir}/#{branch}")
      FileUtils.ln_sf(checkout, "#{branches_path}/#{branch}")
      self
    end

    private
    def remove_old_checkouts(branch)
      max = @options[branch]['checkouts_to_keep']
      dir = "#{@options['target_directory']}/checkouts/#{branch}"
      if (Dir.glob("#{dir}/*").size) > max
        # Here we must delete the oldest checkout
        checkout_to_delete = Dir.glob("#{dir}/*").sort{|a,b| File.new(a).mtime.strftime("%Y%m%d%H%M%S") <=> File.new(b).mtime.strftime("%Y%m%d%H%M%S") }.shift
        FileUtils.rm_r "#{checkout_to_delete}"
      end
    end
  end
end
