require "cuba"
require "basica"

require_relative "lib/service"
require_relative "lib/repository"
require_relative "lib/heroku"
require_relative "lib/json_response"

Cuba.plugin Basica
Cuba.plugin JSONResponse

Cuba.define do
  basic_auth(env) do |_, api_key|
    on ":app/repo" do |app|
      uri = Heroku.git_uri(app, api_key)

      on /(.*)/ do |path|
        on get do
          status, resp = Service.get(uri, path)
          json(status, resp)
        end

        on put do
          status, resp = Service.put(uri, path, req.params)
          json(status, resp)
        end

        on post do
          status, resp = Service.put(uri, path, req.params)
          json(status, resp)
        end

        on delete do
          status, resp = Service.delete(uri, path, req.params)
          json(status, resp)
        end
      end
    end
  end
end
