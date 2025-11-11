# frozen_string_literal: true

require 'json'
require 'logger'
require 'redis'
require 'dry/cli'
require 'securerandom'

require_relative 'jobkiq/version'
require_relative 'jobkiq/cli'
require_relative 'jobkiq/helpers/keys'
require_relative 'jobkiq/queue_management/queue_manager'
require_relative 'jobkiq/queue_management/tags_locker'
require_relative 'jobkiq/queue_management/queue_locker'
require_relative 'jobkiq/redis_connection'
require_relative 'jobkiq/fetcher'
require_relative 'jobkiq/job'
require_relative 'jobkiq/worker'

require_relative '../app/jobs/test_job'

module Jobkiq
  DEFAULT_QUEUE_NAME = 'default'
end
