apps_root = "/apps"
pid_root = "#{apps_root}/pids"
log_root = "#{apps_root}/logs"
site_root = "#{apps_root}/prex.io/current"

pids = {
  :prex_web => "#{pid_root}/prex_web.pid",
  :prex_workers => "#{pid_root}/prex_workers.pid"
}

logs = {
  :prex_web => "#{apps_root}/prex.io/shared/log/development.log",
  :prex_workers => "#{apps_root}/prex.io/shared/log/sidekiq.log"
}

# God.watch do |w|
#   w.name = "redis"
#   w.start = "sudo /usr/local/bin/redis-server /etc/redis.conf"
#   w.keepalive
# end

# God.watch do |w|
#   w.name = "ops-admin"
#   w.dir = "#{apps_root}/ops-admin"
#   w.log = logs[:admin]
#   w.start = "bundle exec rails server -d -p 3005  --pid #{pids[:admin]}"
#   w.pid_file = pids[:admin]
# end

God.watch do |w|
  w.name = "prex_workers"
  w.group = "prex_site"
  w.interval = 30.seconds
  w.dir = site_root
  w.log = logs[:prex_workers]
  # w.pid_file = pids[:prex_workers]
  # w.start = "bundle exec sidekiq --index 0 --pidfile #{pids[:prex_workers]} --environment development --logfile #{logs[:prex_workers]} --daemon"
  w.start = "bundle exec sidekiq --index 0 --environment development --logfile #{logs[:prex_workers]} --daemon"
  w.stop = "bundle exec sidekiqctl stop #{pids[:prex_workers]} 5"
  w.behavior(:clean_pid_file)

  w.transition(:init, { true => :up, false => :start}) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  w.transition(:up, :restart) do |on|
    on.condition(:file_touched) do |c|
      c.interval = 5.seconds
      c.path = File.join(site_root, 'tmp', 'restart.txt')
    end
  end
end

God.watch do |w|
  w.name = "prex_web"
  w.group = "prex_site"
  w.interval = 30.seconds
  w.dir = site_root
  w.log = logs[:prex_web]
  w.pid_file = pids[:prex_web]
  # w.start = "bundle exec rails server -d -p 80 --pid #{pids[:prex_web]}"
  w.start = "bundle exec rails server -d -p 80"
  # w.stop = "kill $(cat #{pids[:prex_web]})"
  w.behavior(:clean_pid_file)

  w.transition(:init, { true => :up, false => :start}) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  w.transition(:up, :restart) do |on|
    on.condition(:file_touched) do |c|
      c.interval = 5.seconds
      c.path = File.join(site_root, 'tmp', 'restart.txt')
    end
  end
end