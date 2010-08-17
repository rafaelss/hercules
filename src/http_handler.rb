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
    yaml = YAML.load_file(@config.config_file)
    req = RequestHandler.new @http_post_content
    if yaml.include? req.repository_name
      resp.status = 200
      git = GitHandler.new yaml[req.repository_name]
      git.deploy_branch(req.branch)
    else
      resp.status = 404
      resp.content = "Repository not found in config!"
    end
    resp.content = ""
    resp.send_response
  end
end

