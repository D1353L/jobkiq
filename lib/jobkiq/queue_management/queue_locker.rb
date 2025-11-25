# frozen_string_literal: true

module Jobkiq
  module QueueManagement
    class QueueLocker
      include Helpers::Keys

      LOCK_EXPIRATION_SEC = 10
      LUA_TRY_LOCK_SCRIPT = <<~LUA
        local locked = redis.call("GET", KEYS[1])
        if locked then
            return false
        end

        return redis.call("SET", KEYS[1], ARGV[1], "NX", "EX", ARGV[2])
      LUA

      def initialize(queue_name:, redis:, worker_id:)
        @redis = redis
        @worker_id = worker_id
        @lock_key = lock_key(queue_name)
      end

      def try_lock
        @redis.eval(LUA_TRY_LOCK_SCRIPT, keys: [@lock_key], argv: [@worker_id, LOCK_EXPIRATION_SEC])
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
