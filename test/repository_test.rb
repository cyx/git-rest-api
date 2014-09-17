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
    @config_ru = (<<-EOT).gsub(/^ {6}/, '')
      app = lambda do |env|
        [200, { 'Content-Type' => 'text/plain' }, ['Hello World']]
      end

      run app
    EOT

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

    dict = obj.to_hash

    assert_equal dict[:type], "file"
    assert_equal dict[:size], 96
    assert_equal dict[:name], "config.ru"
    assert_equal dict[:path], "config.ru"

    assert_equal @config_ru, dict[:content]
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
      content: "",
      size: 0,
      name: "sample.rb",
      path: "lib/sample.rb"
    }]

    assert_equal expected.to_json, list.to_json
  end

  def test_put_file_OK
    params = {
      "data" => @config_ru,
      "commit_message" => "Added README"
    }

    obj = Repository.put(@uri, "README", params)

    assert_equal obj.to_hash[:size],
      Repository.get(@uri, "README").to_hash[:size]

    assert_equal obj.to_hash,
      Repository.get(@uri, "README").to_hash
  end


  # File existing and you try to overwrite that indirectly
  # by an overlapping path
  # i.e. config.ru exists then you try to commit config.ru/foo
  def test_put_file_overlapping
    params = {
      "data" => "",
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
      "commit_message" => "Added foo"
    }

    assert_raise Storage::Exists do
      Repository.put(@uri, "lib", params)
    end
  end

  def test_del_OK
    # Add foo, which we'll remove.
    params = {
      "commit_message" => "Added foo",
      "data" => ""
    }

    Repository.put(@uri, "foo", params)
    Repository.get(@uri, "foo")

    # Remove foo
    params = {
      "commit_message" => "Removed foo"
    }

    Repository.del(@uri, "foo", params)

    assert Storage::Missing do
      Repository.get(@uri, "foo")
    end
  end

  def test_del_missing_file
    # Remove foo
    params = {
      "commit_message" => "Removed foo"
    }

    assert_raise Storage::Missing do
      Repository.del(@uri, "foo", params)
    end
  end
end
