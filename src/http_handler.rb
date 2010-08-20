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
    return send_404 resp, "POST content is null" if post.nil?

    req = RequestHandler.new post.gsub(/^payload=/, "")
    return send_404 resp, "Repository not found in config" unless @config.include? req.repository_name
    return send_404 resp, "Invalid token" unless /\/#{@config[req.repository_name]['token']}$/ =~ @http_path_info

    deploy resp, req
  end

  def deploy resp, req
    begin
      resp.status = 200
      git = GitHandler.new @config[req.repository_name]
      git.deploy_branch(req.branch) do |dir, branch|
        CommandRunner.new(@log).cd(dir){|c| c.run! "bundle install"}
        if File.exists? "#{dir}/lib/deployer.rb"
          require "#{dir}/lib/deployer.rb"
          Dir.chdir(dir) do
            begin
              raise "Error during before_deploy" unless HerculesTriggers::Deployer.before_deploy({:path => dir})
            rescue NameError => e
              # We have to allow the use of a lib/deployer.rb unrelated to Hercules
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
            HerculesTriggers::Deployer.after_deploy({:path => dir})
          rescue NameError => e
            @log.warn "File lib/deployer.rb without HerculesTriggers::Deployer"
          end
        end
      end
      @log.info "After deploy script executed"
      resp.content = "Deploy"
      resp.send_response
    rescue Exception => e
      resp.status = 500
      resp.content = "Error during deploy: #{e.inspect}"
      resp.send_response
      @log.error "Error while deploying branch #{req.branch}: #{e.inspect}"
    end
  end

  def send_404 resp, message
    @log.info "404: #{message}"
    resp.status = 404
    resp.content = message
    resp.send_response
  end
end

