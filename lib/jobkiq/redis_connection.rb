# frozen_string_literal: true

module Jobkiq
  class RedisConnection
    def self.redis
      @redis ||= Redis.new(
        host: ENV['REDIS_HOST'] || 'localhost',
        port: ENV['REDIS_PORT'] || 6379,
        db: ENV['REDIS_DB'] || 0
      )
    end
  end
end
