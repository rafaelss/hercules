module Hercules
  # Class to run the shell commands and store their output.
  # Yes, this class was kindly provided by Integrity.
  # A very nice CI solution built with ruby: http://github.com/integrity/integrity
  # I've made some modifications to store all the commands ran in an output log.
  class CommandRunner
    attr_reader :output

    class Error < StandardError # :nodoc:
    end

    Result = Struct.new(:success, :output)

    # We need to inform the logger object to initialize a CommandRunner
    def initialize(logger)
      @logger = logger
      @output = ""
    end

    # This method will store the output of every command ran by this
    # instance on a file.
    # * path is the file path where we want to store the log.
    def store_output path
      File.open(path, 'a+'){|f| f.write @output }
    end

    # Change the working directory.
    # * dir is the new working directory.
    def cd(dir)
      @dir = dir
      self
    end

    # Run a command using IO.popen, append output to @output
    # * command is the string containing the shell command that will be run.
    def run(command)
      cmd = normalize(command)

      @logger.debug(cmd)

      output = ""
      IO.popen(cmd, "r") { |io| output = io.read }

      @output += output
      Result.new($?.success?, output.chomp)
    end

    # Run a command using IO.popen, append output to @output
    # But we raise an error in case the command is not successful.
    # * command is the string containing the shell command that will be run.
    def run!(command)
      result = run(command)

      unless result.success
        @logger.error(result.output.inspect)
        raise Error, "Failed to run '#{command}'"
      end
      @logger.debug(result.output.inspect)

      result
    end

    # We change the working directory befor executing anything.
    # * cmd is the command to be executed.
    def normalize(cmd)
      if @dir
        "(cd #{@dir} && #{cmd} 2>&1)"
      else
        "(#{cmd} 2>&1)"
      end
    end
  end
end
