# frozen_string_literal: true

module Jobkiq
  class Worker
    TAG_HOLD_EXPIRATION_SEC = 60

    def initialize(queue_name: DEFAULT_QUEUE_NAME, redis: nil, queue_manager: nil, fetcher: nil,
                   logger: nil)
      @queue_name = queue_name
      @worker_id = SecureRandom.uuid
      @running = true
      setup_dependencies(redis:, queue_manager:, fetcher:, logger:)
    end

    def run!
      log_worker_started
      trap_signals
      work_loop
    rescue StandardError => e
      log_worker_crashed(e)
    ensure
      @redis&.close
    end

    private

    def setup_dependencies(redis:, queue_manager:, fetcher:, logger:)
      @redis  = redis  || RedisConnection.redis
      @logger = logger || Logger.new($stdout)

      tags_locker  = QueueManagement::TagsLocker.new(queue_name: @queue_name, redis: @redis)
      queue_locker = QueueManagement::QueueLocker.new(queue_name: @queue_name, redis: @redis, worker_id: @worker_id)

      @fetcher       = fetcher       || Fetcher.new(queue_name: @queue_name, redis: @redis,
                                                    queue_locker:, tags_locker:)
      @queue_manager = queue_manager || QueueManagement::QueueManager.new(queue_name: @queue_name, redis: @redis,
                                                                          tags_locker:)
    end

    def work_loop
      while @running
        @queue_manager.wait_for_job

        job_attrs = @fetcher.claim_next_job

        next unless job_attrs

        execute_job(job_attrs)
        finish_execution(job_attrs)
      end
    end

    def execute_job(job_attrs)
      job_class = job_attrs['class']
      job_args = job_attrs['args']
      job_id = job_attrs['job_id']
      tags = job_attrs['tags']

      @logger.info("Start: class=#{job_class}, job_id=#{job_id}, tags=#{tags}")

      Object.const_get(job_class)
            .new
            .perform(*job_args)
    rescue StandardError => e
      log_job_failed(job_attrs:, exception: e)
    end

    def finish_execution(job_attrs)
      @logger.info("Done: class=#{job_attrs["class"]}, job_id=#{job_attrs["job_id"]}\n")
      @queue_manager.handle_post_execution(job_attrs)
    end

    def log_worker_started
      @logger.info("Jobkiq worker started (queue=#{@queue_name}, worker_id=#{@worker_id})")
    end

    def log_job_failed(job_attrs:, exception:)
      @logger.error("FAILED: class=#{job_attrs["class"]}, job_id=#{job_attrs["job_id"]}, ERROR: #{exception.message}")
      @logger.error(exception.backtrace.join("\n"))
    end

    def log_worker_crashed(exception)
      @logger.error("Worker crashed: #{exception.message}")
      @logger.error(exception.backtrace.join("\n"))
    end

    def shutdown
      puts "\nShutting down..."
      @running = false
    end

    def trap_signals
      Signal.trap('INT')  { shutdown }
      Signal.trap('TERM') { shutdown }
    end
  end
end
