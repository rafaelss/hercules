# coding: utf-8

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'
require File.dirname(__FILE__) + '/request_handler'
require File.dirname(__FILE__) + '/deployer'

class HttpHandler < EventMachine::Connection
  include EventMachine::HttpServer

  def initialize *args
    @config = args[0][:config]
    @log = args[0][:log]
  end

  def process_http_request
    begin
      resp = EventMachine::DelegatedHttpResponse.new( self )
      post = URI.unescape @http_post_content
      @log.debug "Received POST: #{post}"
      return send(resp, 404, "POST content is null") if post.nil?

      req = RequestHandler.new post.gsub(/^payload=/, "")
      return send(resp, 404, "Repository not found in config") unless @config.include? req.repository_name
      return send(resp, 404, "Branch not found in config") unless @config[req.repository_name].include? req.branch
      return send(resp, 404, "Invalid token") unless /\/#{@config[req.repository_name]['token']}$/ =~ @http_path_info

      deploy resp, req
    rescue Exception => e
      @log.error "Error while processing HTTP request: #{e.inspect} \nREQUEST: #{@http_request_method} #{@http_path_info}?#{@http_query_string}\n#{@http_post_content} \nBacktrace: #{e.backtrace}"
      send resp, 500, "Error processing http request: #{e.inspect}"
    end
  end

  def deploy resp, req
    d = Deployer.new(@log, @config[req.repository_name], req.branch)
    begin
      d.deploy
      send resp, 200, "Deploy ok"
    rescue Exception => e
      @log.error "Error while deploying branch #{req.branch}: #{e.inspect} \nBacktrace: #{e.backtrace}"
      send resp, 500, "Error while deploying: #{e.inspect}"
    end
  end

  def send resp, status, message
    @log.info "#{status}: #{message}"
    resp.status = status
    resp.content = message
    resp.send_response
  end
end

