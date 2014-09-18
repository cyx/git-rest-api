require "json"

module JSONResponse
  def json(status, obj)
    res.status = status
    res.headers["Content-Type"] = "application/json"
    res.write(obj.to_json)
  end
end
