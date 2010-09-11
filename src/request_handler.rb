# coding: utf-8
require 'json'

module Hercules
  # Class that knows how to handle deploy requests.
  # This implementation will just parse a JSON as defined by github http hooks.
  # In order to use other hook formats this class should be reimplemented.
  class RequestHandler
    # We must pass the request body.
    # * request_body is a string containing all the request body.
    def initialize(config, log, method, path, query, body)
      @method = method
      @body = body
      @log = log
      @path = path
      @config = config
    end

    def message
      @result ||= process_request
      @result[:message]
    end

    def status
      @result ||= process_request
      @result[:status]
    end

    def process_request
      return {:status => 404, :message => "GET not supported" } if @method == "GET"
      return {:status => 404, :message => "POST content is null"} if @body.nil? 
      return {:status => 404, :message => "Repository #{repository_name} not found in config"} unless @config.include? repository_name
      return {:status => 404, :message => "Branch #{branch} not found in config"} unless @config[repository_name].include? branch
      return {:status => 404, :message => "Invalid token"} unless /\/#{@config[repository_name]['token']}$/ =~ @path
      return {:status => 200, :message => "ok"}
    end

    def parse_body
      post = URI.unescape(@body)
      @log.debug "Received POST: #{post}"
      JSON.parse(post.gsub(/^payload=/, ""))
    end

    def payload
      @payload ||= parse_body
    end

    # Returns the repository name that fired the request.
    def repository_name
      payload['repository']['name']
    end

    # Returns the url of the repository that fired the request.
    def repository_url
      payload['repository']['url']
    end

    # Returns the branch of the repository that fired the request.
    def branch
      payload['ref'].split('/').pop
    end
  end
end
