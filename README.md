# Hercules
      
  Very simple deployment tool. It was made to deploy rails applications using github, bundler.
  This project is in it's early stages of development, so it is not usable yet.
  
## Features

  * Parses github post-receive http hook.
  * Executes a custom pre-deploy script and a post-deploy.
  * Installs gems using Bundler (http://gembundler.com/)
  * Uses the eventmachine http server, little dependencies, simple code.
  
## Installation

  For now you have to clone the repository [hercules](http://github.com/diogob/hercules)
  and run:
  
      $ ruby src/hercules.rb

