# coding: utf-8

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'
require File.dirname(__FILE__) + '/request_handler'
require File.dirname(__FILE__) + '/git_handler'

class HttpHandler < EventMachine::Connection
  include EventMachine::HttpServer

  def initialize *args
    @config = args[0][:config]
    @log = args[0][:log]
  end

  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new( self )
    @log.info "Received POST: #{@http_post_content}"
    return send_404 resp, "POST content is null" if @http_post_content.nil?

    req = RequestHandler.new @http_post_content
    return send_404 resp, "Repository not found in config" unless @config.include? req.repository_name

    resp.status = 200
    git = GitHandler.new @config[req.repository_name]
    git.deploy_branch(req.branch)
    resp.content = "Deploy"
    resp.send_response
    @log.info "Branch #{req.branch} deployed"
  end

  def send_404 resp, message
    @log.info "404: #{message}"
    resp.status = 404
    resp.content = message
    resp.send_response
  end
end

