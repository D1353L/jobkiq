# frozen_string_literal: true

module Jobkiq
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class PerformAsync < Dry::CLI::Command
        desc 'Enqueues async job'

        argument :job_class, required: true
        argument :tags, type: :array, required: true
        option :queue, aliases: ['-q']

        example [
          'perform_async -q queue JobClass tag1,tag2,tag3'
        ]

        def call(job_class:, tags: [], **options)
          queue_name = options[:queue] || DEFAULT_QUEUE_NAME

          job = Object.const_get(job_class)
                      .new(queue_name:)
                      .perform_async(tags:)

          puts "Created job #{job.job_id} (class: #{job.class}, queue: #{queue_name}, tags: [#{job.tags.join(", ")}])"
        end
      end

      class Worker < Dry::CLI::Command
        desc 'Starts worker'

        option :queue, aliases: ['-q']

        example [
          'worker -q fast'
        ]

        def call(**options)
          queue_name = options[:queue] || DEFAULT_QUEUE_NAME

          Jobkiq::Worker.new(queue_name:).run!
        end
      end

      register 'perform_async', PerformAsync
      register 'worker', Worker
    end
  end
end
