root = '/home/fenne035/dev/dpla/dpla.hub'

working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/unicorn/unicorn.log"
stdout_path "#{root}/unicorn/unicorn.log"

# listen "/tmp/unicorn.dplahub.sock"
listen 8082, :tcp_nopush => true
worker_processes 11
timeout 30