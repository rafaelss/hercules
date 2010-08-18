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
    @g = Git.init(dir)
    @g.chdir do
      @g.config('user.name', 'Test User')
      @g.config('user.email', 'email@email.com')
      @g.add("./config.yml")
      @g.commit_all('message')
      @head_sha = @g.gcommit('HEAD').sha
    end
  end

  def generate_commit file_name
    head_sha = @head_sha
    @g.chdir do
      FileUtils.touch file_name
      @g.add("./#{file_name}")
      @g.commit_all("added file: #{file_name}")
      head_sha = @g.gcommit('HEAD').sha
    end
    return head_sha
  end

  def assert_is_checkout(dir)
    assert_equal File.open(File.dirname(__FILE__) + '/fixtures/config.yml').read, File.open(dir + '/config.yml').read
    assert !File.exists?(dir + '/.git')
  end
end
