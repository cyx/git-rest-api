require_relative "payload"

module Service
  def self.get(uri, path)
    try do
      return 200, Repository.get(uri, path)
    end
  end

  def self.put(uri, path, params)
    try do
      payload = Payload.extract(params)

      return 200, Repository.put(uri, path, payload)
    end
  end

  def self.delete(uri, path, params)
    try do
      payload = Payload::Commit.extract(params)

      Repository.del(uri, path, payload)

      return 200, {}
    end
  end

private
  def self.try
    yield
  rescue Payload::Invalid => err
    return 400, { error: err.errors }
  rescue Repository::Forbidden
    return 403, { error: 'Forbidden' }
  rescue Repository::Error
    return 500, { error: 'Internal Server Error' }
  rescue Storage::Missing
    return 404, { error: 'Not Found' }
  rescue Storage::Exists => err
    return 409, { error: '%s already exists' % err.message }
  rescue Storage::Error # Catch all for all Storage errors
    return 400, { error: 'Invalid Request' }
  end
end
