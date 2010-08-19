module HerculesTriggers
  class Deployer
    def self.before_deploy(options)
      true
    end

    def self.after_deploy(options)
      FileUtils.touch "#{options[:path]}/after_deploy"
    end
  end
end
