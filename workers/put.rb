class PUT
  def call(id)
    job = Job[id]
    $stderr.puts "-----> Got job: %s" % job.id

    $stderr.puts "       Repository.put(%s, %s, ...)" %
      [job.uri, job.path]

    # FIXME: Quick hack to make things work for now
    status, response = Service.try do
      Repository.put(job.uri, job.path, job.payload)
    end

    $stderr.puts "       Got response: %s, %s" % [status, response]

    job.done!(response)
    $stderr.puts "       Job done!"
  end
end
