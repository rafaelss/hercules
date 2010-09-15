# coding: utf-8

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'
require File.dirname(__FILE__) + '/request_handler'

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
        req = RequestHandler.new({:config => @config, :log => @log, :method => @http_request_method, :path => @http_path_info, :query => @http_query_string, :body => @http_post_content})
        return send(resp, req.status, req.message)
      rescue Exception => e
        send(resp, 500, "Error while processing HTTP request: #{e.inspect} \nREQUEST: #{@http_request_method} #{@http_path_info}?#{@http_query_string}\n#{@http_post_content}")
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
