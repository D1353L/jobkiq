# frozen_string_literal: true

module Jobkiq
  module Job
    attr_reader :job_id, :tags

    def initialize(queue_name: DEFAULT_QUEUE_NAME, redis: nil, queue_manager: nil)
      @job_id = SecureRandom.uuid
      setup_dependencies(queue_name:, redis:, queue_manager:)
    end

    def perform
      raise NotImplementedError
    end

    def perform_async(tags:)
      @tags = tags
      @queue_manager.enqueue(build_job_attrs(tags:))

      self
    ensure
      @redis&.close
    end

    private

    def setup_dependencies(queue_name:, redis:, queue_manager:)
      @redis = redis || RedisConnection.redis

      @queue_manager = queue_manager || QueueManagement::QueueManager.new(
        queue_name:,
        redis: @redis,
        tags_locker: QueueManagement::TagsLocker.new(queue_name:, redis: @redis)
      )
    end

    def build_job_attrs(tags:)
      {
        'class' => self.class.name,
        'job_id' => @job_id,
        'tags' => stringify_tags(tags)
      }
    end

    def stringify_tags(tags)
      raise StandardError, 'Tags shoud be in array' unless tags.is_a?(Array)

      tags.map(&:to_s)
    end
  end
end
