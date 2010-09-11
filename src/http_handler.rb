# coding: utf-8

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'
require File.dirname(__FILE__) + '/request_handler'
require File.dirname(__FILE__) + '/deployer'

module Hercules
  class HttpHandler < EventMachine::Connection
    include EventMachine::HttpServer

    def initialize *args
      @config = args[0][:config]
      @log = args[0][:log]
    end

    def process_http_request
      begin
        resp = EventMachine::DelegatedHttpResponse.new( self )
        req = RequestHandler.new @config, @log, @http_request_method, @http_path_info, @http_query_string, @http_post_content
        return send(resp, req.status, req.message) unless req.status == 200
        deploy resp, req
      rescue Exception => e
        send resp, 500, "Error while processing HTTP request: #{e.inspect} \nREQUEST: #{@http_request_method} #{@http_path_info}?#{@http_query_string}\n#{@http_post_content}"
        @log.error "Backtrace: #{e.backtrace}"
      end
    end

    def deploy resp, req
      d = Deployer.new(@log, @config[req.repository_name], req.branch)
      begin
        d.deploy
        send resp, 200, "Deploy ok"
      rescue Exception => e
        send resp, 500, "Error while deploying branch #{req.branch}: #{e.inspect}"
        @log.error "Backtrace: #{e.backtrace}"
      end
    end

    def send resp, status, message
      if status == 500
        @log.error "#{status}: #{message}"
      else
        @log.info "#{status}: #{message}"
      end
      resp.status = status
      resp.content = message
      resp.send_response
    end
  end
end
