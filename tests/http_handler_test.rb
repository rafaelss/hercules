# coding: utf-8
require 'tests/startup'
require 'tests/git_setup'
require 'net/http'
require 'uri'
require 'test/unit'

class HttpHandlerTest < Test::Unit::TestCase
  include Startup
  include GitSetup

  def setup
    prepare_startup
    git_setup
    @json_request = %<
{
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
    start_hercules do |pid,log|
      res = Net::HTTP.post_form(URI.parse("http://127.0.0.1:8080/#{token}"), {'payload' => @json_request})
      yield res, log
    end
  end

  def get token
    start_hercules do |pid,log|
      res = Net::HTTP.get(URI.parse("http://127.0.0.1:8080/#{token}"))
      yield res, log
    end
  end

  def test_simple_post
    post "abc" do |res, log|
      log_content = log.read()
      assert_match /Received POST/, log_content
      assert_no_match /Repository .* not found/, log_content
      assert_no_match /Invalid token/, log_content
      assert_no_match /Repository .* not found/, res.body
      assert_is_checkout @config['test_project']['target_directory'] + '/branches/master'
    end
  end

  def test_get
    get "abc" do |res,log|
      assert_no_match /500: Error/, log.read
    end
  end
end
