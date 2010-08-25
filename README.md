# Hercules
      
  Very simple deployment tool. It was made to deploy rails applications using github, bundler.
  This project is in it's early stages of development, so it can be a little rough.
  There will be a gem as soon as it's a little more polished.
  
## Features

  * Parses github post-receive http hook.
  * Executes a custom pre-deploy script and a post-deploy.
  * Installs gems using Bundler (http://gembundler.com/)
  * Uses the eventmachine http server, little dependencies, simple code.
  
## Installation

  For now you have to clone the repository [hercules](http://github.com/diogob/hercules)
  and run:
  
      $ ruby src/hercules.rb

  Take a look at tests/fixtures/config.yml for a sample configuration file and at tests/fixtures/deployer_true.rb for a sample deployer script.

## The deploy hooks
  The deployer scripts should be inside lib/deployer.rb
  Hercules implements two deploy hooks so far: before_deploy and after_deploy.
  They should be coded inside a module called HerculesTriggers in a class Deployer as class methods, moreover they receive an options parameter which contains the path key with the complete deployment path.
  If you do not have a HerculesTriggers module you can use the file lib/deployer.rb and it will be ignored by the deployer.

      module HerculesTriggers
        class Deployer
          def self.before_deploy(options)
            `cp config/database.sample.yml config/database.yml`
          end
          def self.after_deploy(options)
            `kill -HUP \`cat /var/run/unicorn/development.pid\``
          end
        end
      end

