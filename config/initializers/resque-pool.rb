WORKER_CONCURRENCY_SMALL = Integer(ENV["WORKER_CONCURRENCY_SMALL"] || 1)
WORKER_CONCURRENCY_BIG = Integer(ENV["WORKER_CONCURRENCY_BIG"] || 1)
WORKER_CONCURRENCY_MIGRATION = Integer(ENV["WORKER_CONCURRENCY_MIGRATION"] || 1)
WORKER_CONCURRENCY_EXPORT = Integer(ENV["WORKER_CONCURRENCY_EXPORT"] || 1)
WORKER_CONCURRENCY_UPLOAD = Integer(ENV["WORKER_CONCURRENCY_UPLOAD"] || 1)