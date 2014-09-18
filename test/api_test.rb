require "test/unit"
require "rack/test"

require_relative "../server"

class APITest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @uri = URI.parse(ENV.fetch("HEROKU_GIT_URI"))

    @appname = File.basename(@uri.path, ".git")
  end

  def app
    Cuba
  end

  def test_GET_no_authorization
    get url("/")
    assert_response 403, { error: "Forbidden" }
  end

  def test_GET_authorized
    authorize @uri.user, @uri.password
    get url("/")

    assert_equal 200, last_response.status
    assert json_response.kind_of?(Array)

    json_response.each do |elem|
      assert Hash === elem

      assert(elem["type"] =~ /file|directory/)
      assert(elem["encoding"] =~ /base64|UTF-8/)

      assert Integer === elem["size"]
      assert String === elem["path"]
      assert String === elem["name"]
      assert String === elem["content"]
    end
  end

  def test_PUT_and_DELETE
    authorize @uri.user, @uri.password

    params = {
      "type" => "file",
      "content" => "hello world from sample2",
      "commit_message" => "Added sample2",
    }

    # PUT new content
    put url("lib/sample2.rb"), params
    assert_equal 200, last_response.status

    # GET and verify
    get url("lib/sample2.rb")

    content = Base64.decode64(json_response["content"])
    assert_equal params["content"], content

    # DELETE newly added content
    params = {
      "commit_message" => "Deleted sample2"
    }

    delete url("lib/sample2.rb"), params
    assert_equal 200, last_response.status

    get url("lib/sample2.rb")
    assert_equal 404, last_response.status
  end

private
  def url(path)
    "%s/repo/%s" % [@appname, path]
  end

  def json_response
    JSON.parse(last_response.body)
  end

  def assert_response(status, body)
    assert_equal status, last_response.status
    assert_equal body.to_json, last_response.body
  end
end
