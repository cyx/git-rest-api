require_relative "../lib/repository"

require "digest/md5"
require "test/unit"
require "uri"

# NOTE: this test is hard coded against my test heroku
# app, which has a config.ru, Gemfile* by default.
#
# My HEROKU_APP_URI is defined in an .env file not committed
# with the repo.
#
class RepositoryTest < Test::Unit::TestCase
  def setup
    # For speed of testing, we use a local repository. During
    # production everything should just work minus the api key
    # author scraping that will potentially grab the author email.
    @uri = "file://%s" % File.expand_path("../fixture/repo", __FILE__)
  end

  def teardown
    system("rm -rf ./tmp/*")
  end

  def test_get_with_wrong_API_creds
    # This is a real app dummy app I currently have.
    # By passing in a random API we verify that we get
    # a proper exception.
    uri = "https://:wrong_pass@git.heroku.com/boiling-citadel-7602.git"

    assert_raise Repository::Forbidden do
      Repository.get(uri, "config.ru")
    end
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

  def test_put_file_OK
    base64 = "YXBwID0gbGFtYmRhIGRvIHxlbnZ8CiAgWzIwMCwgey" \
      "AnQ29udGVudC1UeXBl\nJyA9PiAndGV4dC9wbGFpbicgfSwgW" \
      "ydIZWxsbyBXb3JsZCddXQplbmQKCnJ1\nbiBhcHAK\n"

    params = {
      "data" => base64,
      "encoding" => "base64",
      "commit_message" => "Added README"
    }

    obj = Repository.put(@uri, "README", params)

    assert_equal obj.to_hash("base64"),
      Repository.get(@uri, "README").to_hash("base64")
  end

  # File existing and you try to overwrite that indirectly
  # by an overlapping path
  # i.e. config.ru exists then you try to commit config.ru/foo
  def test_put_file_overlapping
    params = {
      "data" => "",
      "encoding" => "base64",
      "commit_message" => "Added foo"
    }

    assert_raise Storage::Exists do
      Repository.put(@uri, "config.ru/foo", params)
    end
  end

  # Dir existing and you try to overwrite that indirectly
  # by an overlapping path
  # i.e. lib and you try to create a lib file
  def test_put_file_overlapping_with_dir
    params = {
      "data" => "",
      "encoding" => "base64",
      "commit_message" => "Added foo"
    }

    assert_raise Storage::Exists do
      Repository.put(@uri, "lib", params)
    end
  end
end
