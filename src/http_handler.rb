# coding: utf-8

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'json'

class HttpHandler  < EventMachine::Connection
  include EventMachine::HttpServer

  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new( self )
    resp.status = 200
    resp.content = "Hello World! Your post was: #{@http_post_content}"
    resp.send_response
  end
end

