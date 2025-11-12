# frozen_string_literal: true

module Jobkiq
  module QueueManagement
    class TagsLocker
      include Helpers::Keys

      LOCK_EXPIRATION_SEC = 10

      def initialize(queue_name:, redis:)
        @queue_name = queue_name
        @redis = redis
      end

      def lock(tags:, job_id:)
        tags.each do |tag|
          @redis.set(processing_tag_key(@queue_name, tag), job_id, nx: true, ex: LOCK_EXPIRATION_SEC)
        end
      end

      def release(tags:, job_id:)
        tags.each do |tag|
          key = processing_tag_key(@queue_name, tag)
          val = @redis.get(key)

          @redis.del(key) if val == job_id
        end
      end

      def tags_locked?(tags)
        return false if tags.nil? || tags.empty?

        tags.any? { |tag| @redis.get(processing_tag_key(@queue_name, tag)) }
      end
    end
  end
end
