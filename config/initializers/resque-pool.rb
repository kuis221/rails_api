WORKER_CONCURRENCY_SMALL = Integer(ENV["WORKER_CONCURRENCY_SMALL"] || 5)
WORKER_CONCURRENCY_BIG = Integer(ENV["WORKER_CONCURRENCY_BIG"] || 2)
WORKER_CONCURRENCY_MIGRATION = Integer(ENV["WORKER_CONCURRENCY_MIGRATION"] || 3)