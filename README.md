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
  and run in the application root directory:
  
      $ sudo gem install bundler
      $ bundle install --deployment --without development
      $ ruby src/hercules.rb

  Take a look at tests/fixtures/config.yml for a sample configuration file and at tests/fixtures/deployer_true.rb for a sample deployer script.
  *Important:* that hercules does not work with bundler 0.9.

## The deploy hooks
  The deployer scripts should be inside lib/hercules_triggers.rb
  Hercules implements two deploy hooks so far: before_deploy and after_deploy.
  They should be coded inside a module called Hercules in a class Triggers as class methods, moreover they receive an options parameter which contains: the path key with the complete deployment path, the branch key with the name of the branch to be deployed, and the shell key with  a CommandRunner object to execute shell commands during deploy.
  If you do not have a Hercules module you can use the file lib/hercules_tiggers.rb and it will be ignored by the deployer.

      module Hercules
        class Triggers
          def self.before_deploy(options)
            options[:shell].run "cp config/database.sample.yml config/database.yml"
          end
          def self.after_deploy(options)
            options[:shell].run "kill -HUP `cat /var/run/unicorn/development.pid`"
          end
        end
      end

### Canceling the deploy
  If the before_deploy hook returns anything that evaluate as false the deploy will be cancelled.
  The return value of after_deploy is ignored.  
  Also, you can create a Triggers class without all the hooks, only the implemented ones will be called.

      module Hercules
        class Triggers
          def self.before_deploy(options)
            # This will cancel the deploy
            false
          end
        end
      end

## The JSON interface
  You can check the deployment's status of your projects using GET requests.
  If you access the address where hercules is listening (defaults to 0.0.0.0:8080) in a web browser you can ask for a project and get a JSON with the deployment's status.
  For example, assuming I have the project test_project with the token "abc" using the default configuration I can see its deployment status with:

    curl http://localhost:8080

  Soon we will add a nice web interface with redeploy option and what-not :)
