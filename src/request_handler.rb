# coding: utf-8
require 'json'

module Hercules
  # Class that knows how to handle deploy requests.
  # This implementation will just parse a JSON as defined by github http hooks.
  # In order to use other hook formats this class should be reimplemented.
  class RequestHandler
    # We must pass the request body.
    # * request_body is a string containing all the request body.
    def initialize(request_body)
      @body = JSON.parse(request_body)
    end

    # Returns the repository name that fired the request.
    def repository_name
      @body['repository']['name']
    end

    # Returns the url of the repository that fired the request.
    def repository_url
      @body['repository']['url']
    end

    # Returns the branch of the repository that fired the request.
    def branch
      @body['ref'].split('/').pop
    end
  end
end
