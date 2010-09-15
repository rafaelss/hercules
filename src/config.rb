# coding: utf-8
require 'yaml'

module Hercules
  class InvalidConfig < Exception; end
  class Config
    attr_reader :config

    def initialize(path)
      @config = YAML.load_file(path)
      validate
    end

    def host
      "0.0.0.0"
    end

    def port
      8080
    end

    def projects
      @config.keys
    end

    def self.global_attibutes
      ['host', 'port']
    end

    def self.project_attributes
      ['target_directory', 'repository', 'token']
    end

    def self.branch_attributes
      ['checkout_on_startup', 'checkouts_to_keep']
    end

    def branches
      r = {}
      @config.each do |k,v|
        r[k] = v.keys.find_all{|e| e unless self.class.project_attributes.include?(e)}
      end
      r
    end

    private
    def validate
      raise InvalidConfig.new("Empty config file.") if @config.nil?
      @config.each do |k,v|
        raise InvalidConfig.new("Config file error. #{k} expects a hash of options but got #{v}") unless v.is_a?(Hash)
        # Every project attribute is mandatory
        raise InvalidConfig.new("Config file error. #{k} expects a hash of options but got #{v}") unless self.class.project_attributes & v.keys == self.class.project_attributes
      end
    end
  end
end
