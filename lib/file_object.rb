require "json"
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
    Content.new(File.read(fullpath))
  end

  def content=(data)
    File.open(fullpath, "w") do |f|
      f.write(data)
    end
  end

  def fullpath
    File.join(@dir, @path)
  end

  def to_json(*args)
    to_hash.to_json(*args)
  end

  def to_hash
    {
      type: stat.ftype,
      content: content,
      size: stat.size,
      name: File.basename(path),
      path: path,
    }
  end

  class Content
    def initialize(data)
      @data = data
    end

    def to_json(*args)
      Base64.encode64(@data).to_json(*args)
    end
  end
end
