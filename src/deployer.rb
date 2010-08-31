# coding: utf-8

require File.dirname(__FILE__) + '/git_handler'
require File.dirname(__FILE__) + '/command_runner'

class Deployer
  def initialize(logger, config, branch)
    @log = logger
    @config = config
    @branch = branch
    @cmd = CommandRunner.new(@log)
    @trigger_class = nil
  end

  def has_before_trigger?; (!@trigger_class.nil? and @trigger_class.methods.include?("before_deploy"))  ;end
  def has_after_trigger?;  (!@trigger_class.nil? and @trigger_class.methods.include?("after_deploy"))  ;end

  def look_for_triggers(dir)
    if File.exists? "#{dir}/lib/deployer.rb"
      require "#{dir}/lib/deployer.rb"
      begin
        @log.info "Looking for trigger in #{dir}/lib/deployer.rb"
        return ::HerculesTriggers::Deployer
      rescue NameError => e
        # We have to allow the use of a lib/deployer.rb unrelated to Hercules
        if e.message =~ /uninitialized constant .*HerculesTriggers.*/
          @log.warn "File lib/deployer.rb without HerculesTriggers::Deployer: #{e.inspect}"
          return nil
        end
      end
    end
  end

  def deploy
    git = GitHandler.new @config
    git.deploy_branch(@branch) do |dir, branch|
      @cmd.cd(dir).run!("bundle install")
      @trigger_class = look_for_triggers(dir)
      before_trigger(dir) if has_before_trigger?
    end
    @log.warn "Branch #{@branch} deployed"
    dir = "#{git.branches_path}/#{@branch}"
    after_trigger(dir) if has_after_trigger?
  end

  def before_trigger(dir)
    @log.debug "Executing before_trigger"
    Dir.chdir(dir) do
      raise "before_deploy returned false." unless @trigger_class.before_deploy({:path => dir, :branch => @branch, :shell => @cmd})
    end
  end

  def after_trigger(dir)
    @log.debug "Executing after_trigger"
    Dir.chdir(dir) do
      @trigger_class.after_deploy({:path => dir, :branch => @branch, :shell => @cmd})
      @log.info "After deploy script executed"
    end
  end
end
