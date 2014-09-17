require_relative "file_object"

module Storage
  Error   = Class.new(StandardError)
  Missing = Class.new(Error)
  Exists  = Class.new(Error)

  def self.get(git, path)
    obj = FileObject.new(git.dir.path, path)

    strategy = TYPE[obj.stat.ftype]
    strategy.get(obj)

  rescue Errno::ENOENT
    raise Missing, path
  end

  def self.put(git, path, data)
    obj = FileObject.new(git.dir.path, path)

    Directories.put(obj)
    Files.put(obj, data)

    return obj
  rescue Errno::EEXIST
    raise Exists, path
  end

  module Files
    def self.get(obj)
      return obj
    end

    def self.put(obj, data)
      raise Exists, obj.fullpath if File.directory?(obj.fullpath)

      obj.content = data
    end
  end

  module Directories
    def self.get(obj)
      sanitize(Dir.entries(obj.fullpath)).map do |path|
        FileObject.new(obj.dir, File.join(obj.path, path))
      end
    end

    def self.put(obj)
      FileUtils.mkdir_p(File.dirname(obj.fullpath))
    end

  private
    def self.sanitize(entries)
      entries.reject { |e| e == '.' || e == '..' }
    end
  end

  module Unknown
    NotImplemented = Class.new(StandardError)

    def self.get(obj)
      raise NotImplemented, "GET %s/%s" % [obj.dir, obj.path]
    end
  end

  # Define a default strategy for any kind of file type
  TYPE = Hash.new { |h,k| h[k] = Unknown }

  # These are predefined types. We can add other types
  # as we need them.
  TYPE["file"] = Files
  TYPE["directory"] = Directories
end
