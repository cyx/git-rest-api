require "fileutils"
require "git"
require "digest/sha1"

require_relative "storage"

# FIXME: this all works assuming a repo already exists and
# has an initialized master.
#
# !! Make it also work for newly created repos
#
module Repository
  TMP = File.join(Dir.pwd, "tmp")

  def self.get(uri, path)
    git = open(uri)
    dst = File.join(git.dir.path, path)

    Storage.get(dst)
  end

  def self.post(uri, params)
  end

  def self.put(uri, params)
  end

private
  def self.open(uri)
    # In order to prevent contention between different users,
    # a simple way is to use the uri's sha1 hash together
    # with the repository name as a way to provide a bit
    # of per-user isolation (which is the normal case of
    # concurrency anyway)
    #
    # FIXME: Add some locking for a single user doing multiple
    # concurrent requests. this is more of an edge case than
    # a common case I think.
    name = sprintf('%s-%s' % [File.basename(uri, '.git'), hash(uri)])
    path = File.join(TMP, name)

    git =
      if File.exist?(path)
        pull(path)
      else
        clone(uri, name)
      end

    configure(uri, git)

    return git
  end

  def self.hash(str)
    Digest::SHA1.hexdigest(str)
  end

  # FIXME : This function is only good for master,
  # maybe later on we want to handle different branches.
  def self.pull(path)
    Git.open(path).tap do |g|
      begin
        g.pull
      rescue Git::GitExecuteError => err
        # NOTE: the error I expect from this is that if
        # you have a newly created repository, you won't
        # be able to pull from it initially.
        $stderr.printf("ERR: %s\n", err.message)
      end
    end
  end

  def self.clone(uri, name)
    Git.clone(uri, name, path: TMP)
  end

  # TODO: make this extract the details of the user
  # based on the API key of the URI
  def self.configure(uri, git)
    git.config('user.name', 'John Doe')
    git.config('user.email', 'john@example.com')
  end
end
