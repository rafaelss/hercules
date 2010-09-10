# Yes, this class was kindly provided by Integrity.
# A very nice CI solution built with ruby: http://github.com/integrity/integrity
module Hercules
  class CommandRunner
    attr_reader :output

    class Error < StandardError; end

    Result = Struct.new(:success, :output)

    def initialize(logger)
      @logger = logger
      @output = ""
    end

    def store_output path
      File.open(path, 'a+'){|f| f.write @output }
    end

    def cd(dir)
      @dir = dir
      self
    end

    def run(command)
      cmd = normalize(command)

      @logger.debug(cmd)

      output = ""
      IO.popen(cmd, "r") { |io| output = io.read }

      @output += output
      Result.new($?.success?, output.chomp)
    end

    def run!(command)
      result = run(command)

      unless result.success
        @logger.error(result.output.inspect)
        raise Error, "Failed to run '#{command}'"
      end
      @logger.debug(result.output.inspect)

      result
    end

    def normalize(cmd)
      if @dir
        "(cd #{@dir} && #{cmd} 2>&1)"
      else
        "(#{cmd} 2>&1)"
      end
    end
  end
end
