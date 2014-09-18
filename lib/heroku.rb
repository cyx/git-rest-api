require "requests"

module Heroku
  GIT_URI = "https://:%{key}@git.heroku.com/%{app}.git"
  API_URI = "https://api.heroku.com%s"

  def self.git_uri(app, key)
    GIT_URI % { app: app, key: key }
  end

  def self.account(key)
    account = cache(:account, key) do
      resp = Requests.request("GET", API_URI % "/account",
        auth: ["", key],
        headers: { "Accept" => "application/vnd.heroku+json; version=3" })

      resp.body
    end

    JSON.parse(account)

  rescue JSON::ParserError, Requests::Error
    return {}
  end

private
  # FIXME : make this cache in redis / memcache
  def self.cache(namespace, key)
    key = "%s:%s" % [namespace, Digest::SHA1.hexdigest(key)]

    @_cache[key] ||= yield
  end
  @_cache = {}
end
