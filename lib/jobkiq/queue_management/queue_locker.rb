# frozen_string_literal: true

module Jobkiq
  module QueueManagement
    class QueueLocker
      include Helpers::Keys

      LOCK_EXPIRATION_SEC = 10

      def initialize(queue_name:, redis:, worker_id:)
        @redis = redis
        @worker_id = worker_id
        @lock_key = lock_key(queue_name)
      end

      def try_lock
        return false if @redis.get(@lock_key)

        @redis.set(@lock_key, @worker_id, nx: true, ex: LOCK_EXPIRATION_SEC)
      end

      def release
        return unless @redis.get(@lock_key) == @worker_id

        @redis.del(@lock_key)
      rescue Redis::BaseError => e
        warn "[QueueLocker] Failed to release lock: #{e.message}"
      end
    end
  end
end
