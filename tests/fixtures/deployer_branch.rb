module Hercules
  class Triggers
    def self.before_deploy(options)
      true
    end

    def self.after_deploy(options)
      FileUtils.touch "./branch_name_#{options[:branch]}"
    end
  end
end
