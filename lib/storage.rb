module Storage
  Missing = Class.new(StandardError)

  def self.get(path)
    stat = File.stat(path)

    TYPE[stat.ftype].get(path)

  rescue Errno::ENOENT
    raise Missing, path
  end

  module Files
    def self.get(path)
      File.read(path)
    end
  end

  module Directories
    def self.get(path)
      sanitize(Dir.entries(path))
    end

  private
    def self.sanitize(entries)
      entries.reject { |e| e == '.' || e == '..' }
    end
  end

  module Unknown
    NotImplemented = Class.new(StandardError)

    def self.get(path)
      raise NotImplemented, "GET %s" % path
    end
  end

  # Define a default strategy for any kind of file type
  TYPE = Hash.new { |h,k| h[k] = Unknown }

  # These are predefined types. We can add other types
  # as we need them.
  TYPE['file'] = Files
  TYPE['directory'] = Directories
end
