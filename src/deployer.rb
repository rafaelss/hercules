# coding: utf-8

require File.dirname(__FILE__) + '/git_handler'
require File.dirname(__FILE__) + '/command_runner'

module Hercules
  # The Deployer is responsible for clonning the repository,
  # copying the code, and calling the deploy triggers.
  class Deployer
    # * logger is the object of Logger class that will log the deploy actions.
    # * config is the hash configuration of the project we want to deploy. 
    # Will be a subtree of the configuration YAML
    # * branch is the name of the branch we are deploying.
    def initialize(logger, config, branch)
      @log = logger
      @config = config
      @branch = branch
      @cmd = CommandRunner.new(@log)
      @trigger_class = nil
    end


    # This method will do the deploy: git clone, run bundle install and call the triggers callbacks.
    def deploy
      git = GitHandler.new @config
      git.deploy_branch(@branch) do |dir, branch|
        Bundler.with_clean_env do
          @cmd.cd(dir)
          bundle_path = "#{dir}/../../../bundles/#{@branch}"
          FileUtils.mkdir_p(bundle_path)
          FileUtils.mkdir_p("#{dir}/vendor")
          FileUtils.ln_s(bundle_path, "#{dir}/vendor/bundle", :force => true)
          @cmd.run!("bundle install --deployment")
          @trigger_class = look_for_triggers(dir)
          before_trigger(dir) if has_before_trigger?
        end
      end
      @log.warn "Branch #{@branch} deployed"
      dir = "#{git.branches_path}/#{@branch}"
      Bundler.with_clean_env do
        after_trigger(dir) if has_after_trigger?
      end
    ensure
      # Now we must store the deploy output
      output_dir = "#{@config['target_directory']}/logs/#{@branch}/"
      FileUtils.mkdir_p output_dir
      @cmd.store_output "#{output_dir}/#{git.last_commit}.log"
    end

    private
    # This method will execute the before trigger
    # * dir is the working directory for trigger execution.
    def before_trigger(dir)
      @log.debug "Executing before_trigger"
      Dir.chdir(dir) do
        raise "before_deploy returned false." unless @trigger_class.before_deploy({:path => dir, :branch => @branch, :shell => @cmd})
      end
    end

    # This method will execute the after trigger
    # * dir is the working directory for trigger execution.
    def after_trigger(dir)
      @log.debug "Executing after_trigger"
      Dir.chdir(dir) do
        @trigger_class.after_deploy({:path => dir, :branch => @branch, :shell => @cmd})
      end
      @log.info "After deploy script executed"
    end

    # Check if the project has a before trigger
    def has_before_trigger?; (!@trigger_class.nil? and @trigger_class.methods.include?("before_deploy"))  ;end
    # Check if the project has an after trigger
    def has_after_trigger?;  (!@trigger_class.nil? and @trigger_class.methods.include?("after_deploy"))  ;end

    # Look for triggers in <dir>/lib/hercules_triggers.rb
    # The triggers should be inside a Hercules module in the Triggers class.
    # * dir is the root dir where we will look for the triggers.
    def look_for_triggers(dir)
      if File.exists? "#{dir}/lib/hercules_triggers.rb"
        require "#{dir}/lib/hercules_triggers.rb"
        begin
          @log.info "Looking for trigger in #{dir}/lib/hercules_triggers.rb"
          return ::Hercules::Triggers
        rescue NameError => e
          # We have to allow the use of a lib/hercules_triggers.rb unrelated to Hercules
          if e.message =~ /uninitialized constant .*Hercules.*/
            @log.warn "File lib/deployer.rb without Hercules::Triggers: #{e.inspect}"
            return nil
          end
        end
      end
    end
  end
end
