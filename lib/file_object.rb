require "base64"
require "json"

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

  def set_content(encoding, data)
    File.open(fullpath, "w") do |f|
      f.write(decode("base64", data))
    end
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

  def encode(encoding)
    ENCODING[encoding].encode(content)
  end

  def decode(encoding, data)
    ENCODING[encoding].decode(data)
  end

  module UnknownEncoding
    def self.encode(str)
      raise "Unknown encoding"
    end

    def self.decode(str)
      raise "Unknown encoding"
    end
  end

  module Base64Encoding
    def self.encode(str) Base64.encode64(str) end
    def self.decode(str) Base64.decode64(str) end
  end

  ENCODING = Hash.new { |h,k| h[k] = UnknownEncoding }
  ENCODING["base64"] = Base64Encoding
end
