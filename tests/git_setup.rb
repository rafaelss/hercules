# coding: utf-8
require 'git'
require 'src/git_handler'

module GitSetup
  def git_setup
    @config = YAML.load_file(File.dirname(__FILE__) + '/fixtures/config.yml')
    dir = @config['test_project']['repository'].gsub(/file:\/\//, '')
    FileUtils.rm_rf(dir)
    FileUtils.rm_rf(@config['test_project']['target_directory'])
    FileUtils.mkdir_p(dir)
    FileUtils.cp(File.dirname(__FILE__) + '/fixtures/config.yml', "#{dir}/config.yml")
    FileUtils.cp(File.dirname(__FILE__) + '/fixtures/Gemfile', "#{dir}/Gemfile")
    @g = Git.init(dir)
    @g.chdir do
      @g.config('user.name', 'Test User')
      @g.config('user.email', 'email@email.com')
      @g.add("./config.yml")
      @g.add("./Gemfile")
      @g.commit_all('message')
      @head_sha = @g.gcommit('HEAD').sha
    end
  end

  def generate_bogus_gemfile
    change_repository do
      File.open('./Gemfile', 'a'){|f| f.write('gem "Gem_That_Does_Not_Exist", "0.0.0"') }
    end
  end

  def generate_deployer_false
    change_repository do
      FileUtils.mkdir_p("./lib")
      FileUtils.cp(File.dirname(__FILE__) + '/fixtures/deployer_false.rb', "./lib/deployer.rb")
    end
  end

  def generate_deployer_true
    change_repository do
      FileUtils.mkdir_p("./lib")
      FileUtils.cp(File.dirname(__FILE__) + '/fixtures/deployer_true.rb', "./lib/deployer.rb")
    end
  end

  def generate_deployer_path
    change_repository do
      FileUtils.mkdir_p("./lib")
      FileUtils.cp(File.dirname(__FILE__) + '/fixtures/deployer_path.rb', "./lib/deployer.rb")
    end
  end

  def generate_deployer_exception
    change_repository do
      FileUtils.mkdir_p("./lib")
      FileUtils.cp(File.dirname(__FILE__) + '/fixtures/deployer_exception.rb', "./lib/deployer.rb")
    end
  end

  def generate_deployer_undefined_variable
    change_repository do
      FileUtils.mkdir_p("./lib")
      FileUtils.cp(File.dirname(__FILE__) + '/fixtures/deployer_undefined_variable.rb', "./lib/deployer.rb")
    end
  end

  def generate_bogus_deployer
    change_repository do
      FileUtils.mkdir_p("./lib")
      FileUtils.cp(File.dirname(__FILE__) + '/fixtures/bogus_deployer.rb', "./lib/deployer.rb")
    end
  end

  def generate_commit file_name
    change_repository{ FileUtils.touch file_name }
  end

  def change_repository
    head_sha = @head_sha
    @g.chdir do
      yield
      @g.add("./*")
      @g.commit_all("added files")
      head_sha = @g.gcommit('HEAD').sha
    end
    return head_sha
  end

  def assert_is_checkout(dir)
    assert_equal File.open(File.dirname(__FILE__) + '/fixtures/config.yml').read, File.open(dir + '/config.yml').read
    assert !File.exists?(dir + '/.git')
  end
end
