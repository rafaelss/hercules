# coding: utf-8

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'
require File.dirname(__FILE__) + '/request_handler'
require File.dirname(__FILE__) + '/git_handler'
require File.dirname(__FILE__) + '/command_runner'

class HttpHandler < EventMachine::Connection
  include EventMachine::HttpServer

  def initialize *args
    @config = args[0][:config]
    @log = args[0][:log]
  end

  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new( self )
    post = URI.unescape @http_post_content
    @log.debug "Received POST: #{post}"
    return send(resp, 404, "POST content is null") if post.nil?

    req = RequestHandler.new post.gsub(/^payload=/, "")
    return send(resp, 404, "Repository not found in config") unless @config.include? req.repository_name
    return send(resp, 404, "Branch not found in config") unless @config[req.repository_name].include? req.branch
    return send(resp, 404, "Invalid token") unless /\/#{@config[req.repository_name]['token']}$/ =~ @http_path_info

    deploy resp, req
  end

  def deploy resp, req
    begin
      git = GitHandler.new @config[req.repository_name]
      git.deploy_branch(req.branch) do |dir, branch|
        CommandRunner.new(@log).cd(dir){|c| c.run! "bundle install"}
        if File.exists? "#{dir}/lib/deployer.rb"
          require "#{dir}/lib/deployer.rb"
          Dir.chdir(dir) do
            begin
              raise "before_deploy returned false." unless HerculesTriggers::Deployer.before_deploy({:path => dir, :branch => branch})
            rescue NameError => e
              # We have to allow the use of a lib/deployer.rb unrelated to Hercules
              raise "Error during before_deploy: #{e.message}" if e.message != 'uninitialized constant HttpHandler::HerculesTriggers'
              @log.warn "File lib/deployer.rb without HerculesTriggers::Deployer: #{e.inspect}"
            end
          end
        end
      end
      @log.warn "Branch #{req.branch} deployed"
      dir = "#{git.branches_path}/#{req.branch}"
      if File.exists? "#{dir}/lib/deployer.rb"
        Dir.chdir(dir) do
          begin
            HerculesTriggers::Deployer.after_deploy({:path => dir, :branch => req.branch})
          rescue NameError => e
            raise "Error during before_deploy: #{e.message}" if e.message != 'uninitialized constant HttpHandler::HerculesTriggers'
            @log.warn "File lib/deployer.rb without HerculesTriggers::Deployer"
          end
        end
      end
      @log.info "After deploy script executed"
      send resp, 200, "Deploy ok"
    rescue Exception => e
      @log.error "Error while deploying branch #{req.branch}: #{e.inspect} \nBacktrace: #{e.backtrace}"
      send resp, 500, "Error during deploy: #{e.inspect}"
    end
  end

  def send resp, status, message
    @log.info "#{status}: #{message}"
    resp.status = status
    resp.content = message
    resp.send_response
  end
end

