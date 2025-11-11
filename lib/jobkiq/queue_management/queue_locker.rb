# frozen_string_literal: true

module Jobkiq
  module QueueManagement
    class QueueLocker
      include Helpers::Keys

      LOCK_EXPIRATION_SEC = 10

      def initialize(queue_name:, redis:)
        @redis = redis
        @lock_key = lock_key(queue_name)
        @lock_id = SecureRandom.uuid
      end

      def try_lock
        !!@redis.set(@lock_key, @lock_id, nx: true, ex: LOCK_EXPIRATION_SEC)
      end

      def release
        return unless @redis.get(@lock_key) == @lock_id

        @redis.del(@lock_key)
      rescue Redis::BaseError => e
        warn "[QueueLocker] Failed to release lock: #{e.message}"
      end
    end
  end
end
