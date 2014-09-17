require "base64"

class FileObject
  attr :path
  attr :dir

  def initialize(dir, path)
    @dir = dir
    @path = path
  end

  def stat
    @stat ||= File.stat(fullpath)
  end

  def content
    File.read(fullpath)
  end

  def fullpath
    File.join(@dir, @path)
  end

  def to_json(*args)
    to_hash("base64").to_json(*args)
  end

  def to_hash(encoding)
    {
      type: stat.ftype,
      encoding: encoding,
      content: encode(encoding),
      size: stat.size,
      name: File.basename(path),
      path: path,
    }
  end

  # NOTE: This method serves more as a documentation
  # tool than anything.
  def encode(encoding)
    case encoding
    when "base64"
      Base64.encode64(content)
    else
      raise "No other encodings supported yet."
    end
  end
end
