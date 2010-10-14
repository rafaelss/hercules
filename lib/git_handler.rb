# coding: utf-8
require 'git'

module Hercules
  # Class that handles the git operations.
  class GitHandler
    attr_reader :last_commit
    # We pass an options hash that should contain: 
    #   {
    #   'target_directory' => '/home/hercules/hercules.com', 
    #   'repository' => 'git://github.com/diogob/hercules.git',
    #   'master' => { 'checkouts_to_keep' => 2 },
    #   }
    def initialize(options)
      @options = options
      @last_commit = nil
    end

    # Will export the branch to @options['target_directory']/checkouts/
    # And link it in @options['target_directory']/branches/
    # It uses the commit's sha1 as directory name.
    # * branch is the branch to be deployed, defaults to master.
    def export_branch(branch = 'master')
      tmp_dir = "#{@options['target_directory']}/checkouts/#{branch}/.tmp_#{Time.now.strftime("%Y%m%d%H%M%S")}"
      begin
        repo = Git.clone(@options['repository'], tmp_dir, {:depth => 1})
        repo.checkout("origin/#{branch}")
      rescue Exception => e
        FileUtils.rm_rf repo.dir.to_s unless repo.nil?
        raise "Error while cloning #{@options['repository']}: #{e}"
      end
      @last_commit = repo.gcommit('HEAD').sha
      commit_dir = "#{@options['target_directory']}/checkouts/#{branch}/#{@last_commit}"
      Dir.chdir(repo.dir.to_s) { FileUtils.rm_r '.git' }
      FileUtils.mv repo.dir.to_s, commit_dir
      commit_dir
    end

    # Returns the path to branches' link directory.
    def branches_path
      "#{@options['target_directory']}/branches"
    end

    # Creates and then returns the path to branches' link directory.
    def create_branches_dir
      FileUtils.mkdir_p branches_path
      branches_path
    end

    # Deploys the branch.
    # This means it exports it and removes old checkouts upon a successful completion.
    # It also creates the links' directory and links the checkout.
    # * branch is the branch name to be deployed. Defaults to master.
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
    def remove_old_checkouts(branch) # :nodoc:
      max = @options[branch]['checkouts_to_keep']
      dir = "#{@options['target_directory']}/checkouts/#{branch}"
      if (Dir.glob("#{dir}/*").size) > max
        # Here we must delete the oldest checkout
        checkout_to_delete = Dir.glob("#{dir}/*").sort{|a,b| File.new(a).mtime.strftime("%Y%m%d%H%M%S") <=> File.new(b).mtime.strftime("%Y%m%d%H%M%S") }.shift
        FileUtils.rm_r "#{checkout_to_delete}"
        # Remove log file if it exists
        # To achieve consistency we must remove the log when and only when we remove the checkout
        FileUtils.rm_f "#{@options['target_directory']}/logs/#{checkout_to_delete.split('/').pop}.log"
      end
    end
  end
end
