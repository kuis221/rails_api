# This file is used by Rack-based servers to start the application.

# --- Start of unicorn worker killer code ---
require 'unicorn/worker_killer'

max_request_min =  ENV['MAX_REQUEST_MIN'].to_i || 500
max_request_max =  ENV['MAX_REQUEST_MAX'].to_i || 600
verbose = ENV['WORKER_KILLER_VERBOSE'].nil? ? true : (ENV['WORKER_KILLER_VERBOSE'] == '1')

# Max requests per worker
use Unicorn::WorkerKiller::MaxRequests, max_request_min, max_request_max, verbose

oom_min = ((ENV['OOM_MIN'].to_i || 300) * (1024**2))
oom_max = ((ENV['OOM_MAX'].to_i || 340) * (1024**2))

# Max memory size (RSS) per worker
use Unicorn::WorkerKiller::Oom, oom_min, oom_max
# --- End of unicorn worker killer code ---

require 'gctools/oobgc'
if defined?(Unicorn::HttpRequest)
  use GC::OOB::UnicornMiddleware
end

require ::File.expand_path('../config/environment',  __FILE__)
use Rack::Deflater
run Brandscopic::Application
