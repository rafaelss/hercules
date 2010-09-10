module Hercules
  class Triggers
    def self.before_deploy(options)
      puts "test with #{undefined_variable}"
    end

    def self.after_deploy(options)
      FileUtils.touch "./after_deploy"
    end
  end
end
