# coding: utf-8
require 'tests/git_setup'
require 'src/request_handler'
require 'src/config'
require 'logger'
require 'json'
require 'test/unit'

class RequestHandlerTest < Test::Unit::TestCase
  include GitSetup
  def setup
    git_setup
    @config = ::Hercules::Config.new(File.dirname(__FILE__) + '/fixtures/config.yml')
    @json_request = %<payload={
  "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
  "repository": {
    "url": "file:///tmp/hercules_test_repository",
    "name": "test_project",
    "description": "test repository",
    "watchers": 5,
    "forks": 2,
    "private": 1,
    "owner": {
      "email": "diogob@gmail.com",
      "name": "diogob"
    }
  },
  "commits": [
    {
      "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
      "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
      "author": {
        "email": "chris@ozmm.org",
        "name": "Chris Wanstrath"
      },
      "message": "okay i give in",
      "timestamp": "2008-02-15T14:57:17-08:00",
      "added": ["filepath.rb"]
    },
    {
      "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
      "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
      "author": {
        "email": "chris@ozmm.org",
        "name": "Chris Wanstrath"
      },
      "message": "update pricing a tad",
      "timestamp": "2008-02-15T14:36:34-08:00"
    }
  ],
  "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
  "ref": "refs/heads/master"
}>
  end

  def post token
    handler = Hercules::RequestHandler.new({:config => @config, :log => Logger.new("/dev/null"), :method => "POST", :path => "/github/#{token}", :query => "", :body => @json_request})
    handler.status # just to ensure we process the request before any assert
    handler
  end

  def get path
    handler = Hercules::RequestHandler.new({:config => @config, :log => Logger.new("/dev/null"), :method => "GET", :path => "/#{path}", :query => "", :body => @json_request})
    handler.status # just to ensure we process the request before any assert
    handler
  end

  def test_read_repository_attributes
    handler = Hercules::RequestHandler.new({:config => @config, :log => Logger.new("/dev/null"), :method => "POST", :path => "/github", :query => "", :body => @json_request})
    assert_equal "test_project", handler.repository_name
    assert_equal "file:///tmp/hercules_test_repository", handler.repository_url
    assert_equal "master", handler.branch
  end

  def test_double_post
    test_simple_post
    test_simple_post
  end

  def test_could_not_install_gem
    generate_bogus_gemfile
    res = post "abc"
    assert_match /Failed to run/, res.message
    assert_equal 500, res.status
    assert !File.exists?(@config['test_project']['target_directory'] + '/branches/master')
  end

  def test_could_install_gem
    generate_gemfile_with_gem
    res = post "abc"
    assert_no_match /Failed to run/, res.message
    assert_equal 200, res.status
    assert_is_checkout @config['test_project']['target_directory'] + '/branches/master'
    assert File.exists?(@config['test_project']['target_directory'] + '/bundles/master')
    assert !File.exists?(@config['test_project']['target_directory'] + '/bundles/master/master')
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master/vendor/bundle')
  end


  def test_simple_post
    res = post "abc"
    assert_no_match /Repository .* not found/, res.message
    assert_equal 200, res.status
    assert_is_checkout @config['test_project']['target_directory'] + '/branches/master'
  end

  def test_invalid_token
    res = post "invalid_token"
    assert_match /Invalid token/, res.message
    assert_equal 403, res.status
    assert !File.exists?(@config['test_project']['target_directory'] + '/branches/master')
  end

  def test_repository_not_found
    @json_request = @json_request.gsub(/test_project/, "project_that_does_not_exist")
    res = post "abc"
    assert_equal 404, res.status
    assert_match /Repository .* not found/, res.message
  end

  def test_branch_not_found
    @json_request = @json_request.gsub(/master/, "branch_that_does_not_exist")
    res = post "abc"
    assert_equal 404, res.status
    assert_match /Branch .* not found/, res.message
  end

  def test_deployer_false
    generate_deployer "deployer_false"
    res = post "abc"
    assert_equal 500, res.status
    assert_match /Error while deploying/, res.message
    assert !File.exists?(@config['test_project']['target_directory'] + '/branches/master')
    assert_equal 1, Dir.glob(@config['test_project']['target_directory'] + '/logs/master/*').size
  end

  def test_deployer_true
    generate_deployer "deployer_true"
    res = post "abc"
    assert_equal 200, res.status
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master')
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master/after_deploy')
  end

  def test_bogus_deployer
    generate_deployer "bogus_deployer"
    res = post "abc"
    assert_equal 200, res.status
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master')
  end

  def test_deployer_path
    generate_deployer "deployer_path"
    res = post "abc"
    assert_equal 200, res.status
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master')
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master/after_deploy')
  end

  def test_deployer_exception
    generate_deployer "deployer_exception"
    res = post "abc"
    assert_equal 500, res.status
    assert_match /Error while deploying/, res.message
    assert !File.exists?(@config['test_project']['target_directory'] + '/branches/master')
  end

  def test_deployer_undefined_variable
    generate_deployer "deployer_undefined_variable"
    res = post "abc"
    assert_equal 500, res.status
    assert_match /Error while deploying/, res.message
    assert !File.exists?(@config['test_project']['target_directory'] + '/branches/master')
  end

  def test_deployer_branch
    generate_deployer "deployer_branch"
    res = post "abc"
    assert_equal 200, res.status
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master')
    assert File.exists?(@config['test_project']['target_directory'] + '/branches/master/branch_name_master')
  end

  def test_get_project_root_with_right_token
    res = get "test_project/abc"
    assert_equal 200, res.status
    assert_equal({'master' => {'deployed' => false}, 'test' => {'deployed' => false}}, JSON.parse(res.message))
  end

  def test_get_project_root_with_wrong_token
    res = get "test_project/wrong_token"
    assert_equal 403, res.status
    assert_match /Invalid token/, res.message
  end

  def test_get_project_root_with_right_token_after_deploy
    res = post "abc"
    assert_equal 200, res.status
    res = get "test_project/abc"
    assert_equal 200, res.status
    log_path = Dir.glob(@config['test_project']['target_directory'] + '/logs/master/*').pop
    checkout = log_path.split('/').pop.gsub(/\.log/, '')
    output = ""
    File.open(log_path){|f| output = f.read }
    timestamp = File.mtime(@config['test_project']['target_directory'] + '/branches/master').strftime("%Y-%m-%d %H:%M:%S")
    assert_equal({'master' => {'deployed' => true, 'checkouts' => {checkout => {'timestamp' => timestamp, 'output' => output}}}, 'test' => {'deployed' => false}}, JSON.parse(res.message))
  end

  def test_get_should_not_return_error_upon_non_existent_log_file
    res = post "abc"
    assert_equal 200, res.status
    log_path = Dir.glob(@config['test_project']['target_directory'] + '/logs/master/*').pop
    FileUtils.rm_f(log_path)
    res = get "test_project/abc"
    assert_equal 200, res.status
    checkout = log_path.split('/').pop.gsub(/\.log/, '')
    timestamp = File.mtime(@config['test_project']['target_directory'] + '/branches/master').strftime("%Y-%m-%d %H:%M:%S")
    assert_equal({'master' => {'deployed' => true, 'checkouts' => {checkout => {'timestamp' => timestamp}}}, 'test' => {'deployed' => false}}, JSON.parse(res.message))
  end
end

