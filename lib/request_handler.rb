# coding: utf-8
require 'json'
require 'uri'
require File.dirname(__FILE__) + '/deployer'

module Hercules
  # Class that knows how to handle deploy requests.
  # This implementation will just parse a JSON as defined by github http hooks.
  # In order to use other hook formats this class should be reimplemented.
  class RequestHandler
    # We must pass the request data (method, path, query and body).
    # * options is a hash containing all the request data described above plus the logger and the config hash.
    def initialize(options)
      @method = options[:method]
      @body = options[:body]
      @log = options[:log]
      @path = options[:path]
      @config = options[:config]
    end

    # Returns the message generated as response for the request passed in the initializer.
    # We also store the message for further queries.
    def message
      @result ||= process_request
      @result[:message]
    end

    # Returns the status generated as response for the request passed in the initializer.
    # We also store the status for further queries.
    def status
      @result ||= process_request
      @result[:status]
    end

    # Returns the repository name that fired the request.
    def repository_name
      return payload['repository']['name'] if @method == "POST"
      return @path.split('/')[1] if @method == "GET"
    end

    # Returns the security token that fired the request.
    def request_token 
      @path.split('/')[2]
    end

    # Returns true whenever the request made was a HDI request
    def request_hdi?
      @path.split('/')[3] == 'hdi' and @method == "GET"
    end

    # Returns the assembled HDI
    def hdi
    end

    # Returns the url of the repository that fired the request.
    def repository_url
      payload['repository']['url']
    end

    # Returns the branch of the repository that fired the request.
    def branch
      payload['ref'].split('/').pop
    end

    private
    def process_request
      @method == "GET" ? process_get : process_post
    end

    def project_json
      response = {}
      @config.branches[repository_name].each do |k|
        deployed = File.exist?("#{@config[repository_name]['target_directory']}/branches/#{k}")
        response[k] = {:deployed => deployed}
        if deployed
          checkouts = {}
          Dir.glob("#{@config[repository_name]['target_directory']}/checkouts/#{k}/*").each do |path|
            output = ""
            checkout = path.split('/').pop
            begin
              File.open("#{@config[repository_name]['target_directory']}/logs/#{k}/#{checkout}.log"){|f| output = f.read }
              checkouts[checkout] = {:timestamp => File.mtime(path).strftime("%Y-%m-%d %H:%M:%S"), :output => output}
            rescue Errno::ENOENT => e
              checkouts[checkout] = {:timestamp => File.mtime(path).strftime("%Y-%m-%d %H:%M:%S")}
            end
          end
          response[k][:checkouts] = checkouts
        end
      end
      response.to_json
    end

    def process_get
      return {:status => 402, :message => "Repository not found"} if @config[repository_name].nil?
      return {:status => 403, :message => "Invalid token"} unless @config[repository_name]['token'] == request_token
      return {:status => 200, :message => hdi } if request_hdi?

      # Otherwise we must return the json with project data
      {:status => 200, :message => project_json }
    end

    def process_post
      return {:status => 404, :message => "POST content is null"} if @body.nil? 
      return {:status => 404, :message => "Repository #{repository_name} not found in config"} unless @config.include? repository_name
      return {:status => 404, :message => "Branch #{branch} not found in config"} unless @config[repository_name].include? branch
      return {:status => 403, :message => "Invalid token"} unless @config[repository_name]['token'] == request_token
      deploy
    end

    # Call the Deployer class to do the deploy magic.
    # To implement a diferent SCM we will need to rewrite the Deployer and this method.
    def deploy
      d = Deployer.new(@log, @config[repository_name], branch)
      begin
        d.deploy
        return {:status => 200, :message => "ok"}
      rescue Exception => e
        @log.error "Backtrace: #{e.backtrace}"
        return {:status => 500, :message => "Error while deploying branch #{branch}: #{e.inspect}"}
      end
    end

    # Parses the request body (only for POST)
    # Here is the github specific code.
    def parse_body
      post = URI.unescape(@body)
      @log.debug "Received POST: #{post}"
      JSON.parse(post.gsub(/^payload=/, ""))
    end

    # Here we call the body parser and store the result for further queries.
    def payload
      @payload ||= parse_body
    end

  end
end
