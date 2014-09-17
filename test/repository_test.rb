require_relative "../lib/repository"

require "digest/md5"
require "test/unit"

# NOTE: this test is hard coded against my test heroku
# app, which has a config.ru, Gemfile* by default.
#
# My HEROKU_APP_URI is defined in an .env file not committed
# with the repo.
#
class RepositoryTest < Test::Unit::TestCase
  def setup
    @uri = ENV.fetch("HEROKU_APP_URI")
  end

  def test_get_existing
    # For the purposes of this test, the assumption is that
    # config.ru won't change, and hence we can check against
    # this hard coded md5 of the file I have.
    expected_md5 = "85fce1517d753dfd29094642bc15933b"

    obj = Repository.get(@uri, "config.ru")

    assert_equal expected_md5,
      Digest::MD5.hexdigest(obj.content)

    dict = obj.to_hash("base64")

    assert_equal dict[:type], "file"
    assert_equal dict[:encoding], "base64"
    assert_equal dict[:size], 96
    assert_equal dict[:name], "config.ru"
    assert_equal dict[:path], "config.ru"

    base64 = "YXBwID0gbGFtYmRhIGRvIHxlbnZ8CiAgWzIwMCwgey" \
      "AnQ29udGVudC1UeXBl\nJyA9PiAndGV4dC9wbGFpbicgfSwgW" \
      "ydIZWxsbyBXb3JsZCddXQplbmQKCnJ1\nbiBhcHAK\n"

    assert_equal base64, dict[:content]
  end

  def test_get_missing
    assert_raise Storage::Missing do
      Repository.get(@uri, "non_existent_file")
    end
  end

  def test_path_in_nested_dir
    assert_equal "lib/sample.rb",
      Repository.get(@uri, "lib/sample.rb").path
  end

  def test_get_dir
    list = Repository.get(@uri, "lib")

    expected = [{
      type: "file",
      encoding: "base64",
      content: "",
      size: 0,
      name: "sample.rb",
      path: "lib/sample.rb"
    }]

    assert_equal expected.to_json, list.to_json
  end
end
