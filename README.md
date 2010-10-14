# Hercules
      
  Very simple deployment tool. It was made to deploy rails applications using github, bundler.
  
## Features

  * Parses github post-receive http hook.
  * Executes a custom pre-deploy script and a post-deploy.
  * Installs gems using Bundler (http://gembundler.com/)
  * Uses the eventmachine http server, little dependencies, simple code.
  
## Roadmap

  * Allow end users to ask for redeploy.
  * Allow end user to rollback deployments.
  * Change checkout color according to deployment status.
  * Show commit messages with the checkout sha1.
  * Implement on_error trigger.
  * Put some code ready for sending emails (to be used inside on_error triggers).
  * Display time in a [military fashion](http://en.wikipedia.org/wiki/24-hour_clock#Military_time)

## Installation

  For now you have to clone the repository [hercules](http://github.com/diogob/hercules)
  and run in the application root directory:

      $ gem install hercules
      $ hercules --help

  Take a look at tests/fixtures/config.yml for a sample configuration file and at tests/fixtures/deployer_true.rb for a sample deployer script.
  *Very important:* Hercules does not work with bundler 0.9.

### Installing the service hook in your github project
  It is necessary to notify hercules whenever changes are made to your project's repository. So we need to setup some service hooks in the github admin interface (which you can access using the "admin" button in your github project page).
  In your project's github admin interface, go to "service hooks" -> Post-Receive URLs.
  Then you put the URL that will call hercules in the blank textbox and click "Update Settings".
  Your URL should look like:  
    http://yourdomain.tld/github/security_token

  Where github is a constant string, and security token is a string that you will put inside the config.yml.  
  You will need only one service hook for each server you want to deploy to. When you deploy several branches to the same server hercules will diferentiate between them through the information that github sends along with the notification.

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
  If you access the address where hercules is listening (defaults to 0.0.0.0:49456) in a web browser you can ask for a project and get a JSON with the deployment's status.
  For example, assuming I have the project test_project with the token "abc" using the default configuration I can see its deployment status with:

    curl http://localhost:49456/test_project/abc

## The HDI
  There is a very simple web interface that relies on javascript to parse and present the JSON. The plan is to improve this interface over time. This web interface is unique for each project, you can access our example project's HDI in http://localhost:49456/test_project/abc/hdi
