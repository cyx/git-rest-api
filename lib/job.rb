require "ohm"

Ohm.redis = Redic.new(ENV.fetch("REDIS_URL"))

class Job < Ohm::Model
  attribute :uri
  attribute :path
  attribute :serialized_payload

  def self.generate(uri, path, payload)
    create(uri: uri,
           path: path,
           serialized_payload: payload.to_json)
  end

  def payload
    JSON.parse(serialized_payload)
  end

  def done!(response)
    redis.call("LPUSH", key[:status], response.to_json)
  end

  def wait!(timeout = 30)
    redis.call("BLPOP", key[:status], timeout)
  end
end
