# frozen_string_literal: true

module Jobkiq
  class Fetcher
    include Helpers::Keys

    BATCH_SIZE = 10
    MAX_OFFSET = 1000

    def initialize(queue_name:, redis:, queue_locker: nil, tags_locker: nil)
      @redis = redis
      @queue_key = queue_key(queue_name)
      @queue_locker = queue_locker || QueueManagement::QueueLocker.new(queue_name:, redis:)
      @tags_locker = tags_locker || QueueManagement::TagsLocker.new(queue_name:, redis:)
    end

    def claim_next_job
      return nil unless @queue_locker.try_lock

      claimed_job = find_and_claim_next_job

      return nil unless claimed_job

      @tags_locker.lock(tags: claimed_job['tags'], job_id: claimed_job['job_id'])

      claimed_job
    ensure
      @queue_locker.release
    end

    private

    def find_and_claim_next_job
      offset = 0

      while offset <= MAX_OFFSET
        job_jsons = fetch_batch(offset)

        return nil if job_jsons.empty?

        job = find_eligible_job(job_jsons)
        return job if job

        offset += BATCH_SIZE
      end

      nil
    end

    def fetch_batch(offset)
      @redis.zrange(@queue_key, offset, offset + BATCH_SIZE - 1)
    end

    def find_eligible_job(job_jsons)
      job_jsons.each do |job_json|
        job = JSON.parse(job_json)

        next if @tags_locker.tags_locked?(job['tags'])

        return claim_job(job, job_json)
      end
      nil
    end

    def claim_job(job, job_json)
      removed = @redis.zrem(@queue_key, job_json)
      removed ? job : nil
    end
  end
end
