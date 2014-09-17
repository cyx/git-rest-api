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
    expected_md5 = '85fce1517d753dfd29094642bc15933b'

    assert_equal expected_md5,
      Digest::MD5.hexdigest(Repository.get(@uri, 'config.ru').content)
  end

  def test_get_missing
    assert_raise Storage::Missing do
      Repository.get(@uri, 'non_existent_file')
    end
  end

  def test_get_dir
    assert_equal ['sample.rb'], Repository.get(@uri, 'lib').map(&:path)
  end
end

