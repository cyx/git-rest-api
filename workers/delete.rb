class DELETE
  def call(id)
    job = Job[id]
    $stderr.puts "-----> Got job: %s" % job.id

    $stderr.puts "       Repository.del(%s, %s, ...)" %
      [job.uri, job.path]

    response = Repository.del(job.uri, job.path, job.payload)
    $stderr.puts "       Got response: %s" % response

    job.done!(response)
    $stderr.puts "       Job done!"
  end
end
