# frozen_string_literal: true

module Jobkiq
  module QueueManagement
    class QueueManager
      include Helpers::Keys

      WAIT_FOR_JOB_SEC = 10

      def initialize(queue_name:, redis:, tags_locker:)
        @redis = redis
        @tags_locker = tags_locker
        @queue_key = queue_key(queue_name)
        @wakeup_key = wakeup_key(queue_name)
      end

      def enqueue(job_attrs)
        push_job_record(job_attrs)
        refresh_wakeup
      end

      def handle_post_execution(job_attrs)
        release_tags(job_attrs)
        refresh_wakeup
      end

      def wait_for_job
        @redis.blpop(@wakeup_key, timeout: WAIT_FOR_JOB_SEC)
      end

      private

      def push_job_record(job_attrs)
        @redis.zadd(@queue_key, current_timestamp, job_attrs.to_json)
      end

      def refresh_wakeup
        @redis.lpush(@wakeup_key, '1')
        @redis.ltrim(@wakeup_key, 0, 0)
      end

      def release_tags(job_attrs)
        @tags_locker.release(tags: job_attrs['tags'], job_id: job_attrs['job_id'])
      end

      def current_timestamp
        Time.now.to_f.truncate(6)
      end
    end
  end
end
