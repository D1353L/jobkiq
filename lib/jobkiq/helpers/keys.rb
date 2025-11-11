# frozen_string_literal: true

module Jobkiq
  module Helpers
    module Keys
      DEFAULT_QUEUES_PATH = 'jobkiq:queue'
      DEFAULT_PROCESSING_TAGS_PATH = 'jobkiq:processing:queue'
      DEFAULT_WAKEUP_LIST_PATH = 'jobkiq:wakeup'
      DEFAULT_LOCK_PATH = 'jobkiq:lock:queue'

      def queue_key(queue)
        "#{DEFAULT_QUEUES_PATH}:#{queue}"
      end

      def wakeup_key(queue)
        "#{DEFAULT_WAKEUP_LIST_PATH}:#{queue}"
      end

      def lock_key(queue)
        "#{DEFAULT_LOCK_PATH}:#{queue}"
      end

      def processing_tag_key(queue, tag)
        "#{DEFAULT_PROCESSING_TAGS_PATH}:#{queue}:tag:#{tag}"
      end
    end
  end
end
