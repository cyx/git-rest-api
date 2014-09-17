require_relative "file_object"

module Storage
  Missing = Class.new(StandardError)

  def self.get(git, path)
    obj = FileObject.new(git.dir.path, path)

    TYPE[obj.stat.ftype].get(obj)

  rescue Errno::ENOENT
    raise Missing, path
  end

  module Files
    def self.get(obj)
      return obj
    end
  end

  module Directories
    def self.get(obj)
      sanitize(Dir.entries(obj.fullpath)).map do |path|
        FileObject.new(obj.dir, path)
      end
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
  TYPE['file'] = Files
  TYPE['directory'] = Directories
end
