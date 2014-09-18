module Heroku
  GIT_URI = "https://:%{key}@git.heroku.com/%{app}.git"

  def self.git_uri(app, key)
    GIT_URI % { app: app, key: key }
  end
end
