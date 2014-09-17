class FileObject
  attr :path

  def initialize(path)
    @path = path
  end

  def content
    File.read(path)
  end
end
