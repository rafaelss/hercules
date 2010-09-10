# coding: utf-8
require 'json'

module Hercules
  class RequestHandler
    def initialize(request_body)
      @body = JSON.parse(request_body)
    end

    def repository_name
      @body['repository']['name']
    end

    def repository_url
      @body['repository']['url']
    end

    def branch
      @body['ref'].split('/').pop
    end
  end
end
