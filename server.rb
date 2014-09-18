require "cuba"
require "basica"

require_relative "lib/service"
require_relative "lib/repository"
require_relative "lib/heroku"
require_relative "lib/json_response"

Ohm.redis = Redic.new(ENV.fetch("REDIS_URL"))
Ost.redis = Redic.new(ENV.fetch("REDIS_URL"))

Cuba.plugin Basica
Cuba.plugin JSONResponse

Cuba.define do
  begin
    basic_auth(env) do |_, api_key|
      on ":app/repo" do |app|
        uri = Heroku.git_uri(app, api_key)

        on /(.*)/ do |path|
          # Eliminate leading slashes for uniformity.
          path = path.gsub(/^\//, '')

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

          # This is a sort of joke from hipchat yesterday:
          #
          # Naaman Newbold: brownie points would be supporting PATCH
          #
          on req.patch? do
            status, resp = Service.put(uri, path, req.params)
            json(status, resp)
          end
        end
      end
    end
  rescue RuntimeError
    on default do
      json(403, { error: 'Forbidden' })
    end
  end
end
