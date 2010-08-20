module HerculesTriggers
  class Deployer
    def self.before_deploy(options)
      true
    end

    def self.after_deploy(options)
      FileUtils.touch "./after_deploy"
    end
  end
end
