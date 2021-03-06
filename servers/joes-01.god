apps_root = "/srv"
site_root = "#{apps_root}/prex.io/current"

pids = {
  :prex_web => "#{apps_root}/prex.io/shared/tmp/pids/server.pid",
  :prex_workers => "#{apps_root}/prex.io/shared/tmp/pids/sidekiq.pid"
}

logs = {
  :prex_web => "#{apps_root}/prex.io/shared/log/development.log",
  :prex_workers => "#{apps_root}/prex.io/shared/log/sidekiq.log"
}

God.watch do |w|
  w.name = "prex_web"
  w.group = "prex_site"
  w.interval = 30.seconds
  w.dir = site_root
  w.log = logs[:prex_web]
  w.pid_file = pids[:prex_web]
  w.start = "bundle exec rails server -d -p 3000"
  w.stop = "kill $(cat #{pids[:prex_web]})"
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
  w.name = "prex_workers"
  w.group = "prex_site"
  w.interval = 30.seconds
  w.dir = site_root
  w.log = logs[:prex_workers]
  w.pid_file = pids[:prex_workers]
  w.start = "bundle exec sidekiq -d -L log/sidekiq.log -P #{pids[:prex_workers]}"
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