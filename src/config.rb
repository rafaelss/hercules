# coding: utf-8
require 'yaml'

module Hercules
  class InvalidConfig < Exception; end
  class Config
    def [](k)
      @config[k]
    end

    def each
      @config.each do |k,v|
        yield(k,v)
      end
    end

    def include?(k)
      @config.include?(k)
    end

    def initialize(path)
      @config = YAML.load_file(path)
      validate
    end

    def host
      @config['host'] || "0.0.0.0"
    end

    def port
      @config['port'] || 8080
    end

    def projects
      p = {}
      @config.each do |k,v| 
        p[k] = v unless self.class.global_attributes.include?(k)
      end
      p
    end

    def self.global_attributes
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
      projects.each do |k,v|
        r[k] = v.keys.find_all{|e| e unless self.class.project_attributes.include?(e)}
      end
      r
    end

    private
    def validate
      # We need to test projects.empty? to cover cases where the config has only global attributes set.
      raise InvalidConfig.new("Empty config file.") if @config.nil? or projects.empty?
      projects.each do |k,v|
        raise InvalidConfig.new("Config file error. #{k} expects a hash of options but got #{v}") unless v.is_a?(Hash)
        # Every project attribute is mandatory
        raise InvalidConfig.new("Config file error. #{k} expects a hash of options but got #{v}") unless self.class.project_attributes & v.keys == self.class.project_attributes
      end
    end
  end
end
