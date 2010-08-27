#!/usr/bin/env ruby
# coding: utf-8

require 'rubygems'
require 'bundler'
Bundler.setup

require 'optparse'
require 'ostruct'
require 'yaml'

require File.dirname(__FILE__) + '/http_handler'

class Hercules
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin

    # Set default options
    @options = OpenStruct.new
    @options.config_file = 'config.yml'
    @options.verbose = false
    @options.log_file = nil
    @options.pid_file = 'hercules.pid'
    @options.foreground = false

    @config = nil
    @pid_file = nil
    @log = nil
  end

  def run
    parse_options
    set_logger
    read_config
    be_verbose if @options.verbose

    # if -f is not present we fork into the background and write hercules.pid
    @options.foreground ? process_command : daemonize
    @log.close  
  end


  protected
  def exit_gracefully
    remove_pid
    @log.info "Terminating hercules..." 
    @log.close unless @log.nil? rescue nil
    exit 0
  end

  def remove_pid
    if !@pid_file.nil? and File.exist? @pid_file
      @log.info "Removing pid file #{@pid_file}..." 
      File.unlink @pid_file
    end
  end

  def read_config    
    begin
      @config = YAML.load_file( @options.config_file )       
    rescue Exception => e      
      @log.fatal "Error reading config file #{@options.config_file}: #{e.inspect}"
      exit
    end
  end

  def set_logger
    require 'logger'
    if @options.log_file.nil?
      @log = Logger.new(STDERR)
    else
      @log = Logger.new(@options.log_file, 'daily')
    end
    @log.level = Logger::INFO
  end

  def daemonize
    begin
      @pid_file = @options.pid_file 
      pid = fork do
        process_command
      end
      File.open(@pid_file, 'w+'){|f| f.write pid.to_s }
      Process.detach(pid)
    rescue Exception => e
      @log.fatal "Error while daemonizing: #{e.inspect}"
      exit
    end
  end

  def parse_options
    opts = OptionParser.new 
    opts.on('-v', '--version')            { puts "hercules version #{VERSION}" ; exit 0 }
    opts.on('-h', '--help')               { puts opts; exit 0  }
    opts.on('-V', '--verbose')            { @options.verbose = true }  
    opts.on('-f', '--foreground')         { @options.foreground = true }
    opts.on('-l', '--log log_file')       { |log_file| @options.log_file = log_file }
    opts.on('-p', '--pid pid_file')       { |pid_file| @options.pid_file = pid_file }
    opts.on('-c', '--conf config_file')   { |conf| @options.config_file = conf }

    opts.parse!(@arguments)
  end

  def process_command
    EventMachine::run do
      Signal.trap("TERM") do 
        exit_gracefully
      end
      EventMachine.epoll
      host = @config['host'] || "0.0.0.0"
      port = @config['port'] || 8080
      EventMachine::start_server(host, port, HttpHandler, {:log => @log, :config => @config})
      @log.info "Listening on #{host}:#{port}..."
    end
  end

  def parse_options
    opts = OptionParser.new 
    opts.on('-v', '--version')            { puts "Hercules version #{VERSION}" ; exit 0 }
    opts.on('-h', '--help')               { puts opts; exit 0  }
    opts.on('-V', '--verbose')            { @options.verbose = true }  
    opts.on('-f', '--foreground')         { @options.foreground = true }
    opts.on('-l', '--log log_file')       { |log_file| @options.log_file = log_file }
    opts.on('-p', '--pid pid_file')       { |pid_file| @options.pid_file = pid_file }
    opts.on('-c', '--conf config_file')   { |conf| @options.config_file = conf }
    opts.parse!(@arguments)
  end

  def be_verbose
    @log.info "Start at #{DateTime.now}"
    @log.info "Options:\n"
    @options.marshal_dump.each do |name, val|        
      @log.info "  #{name} = #{val}"
    end
    @log.level = Logger::DEBUG
  end
end

if __FILE__ == $0
  app = Hercules.new(ARGV, STDIN)
  app.run
end
