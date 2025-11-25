# spec/jobkiq/job_spec.rb
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jobkiq::Job do
  let(:job_class) do
    Class.new do
      include Jobkiq::Job
    end
  end

  let(:redis_mock) { MockRedis.new }
  let(:queue_manager_double) { instance_double(Jobkiq::QueueManagement::QueueManager, enqueue: true) }

  before do
    allow(Jobkiq::RedisConnection).to receive(:redis).and_return(redis_mock)
    allow(Jobkiq::QueueManagement::QueueManager).to receive(:new).and_return(queue_manager_double)
    allow(SecureRandom).to receive(:uuid).and_return('123-uuid')
  end

  describe '#initialize' do
    it 'sets up redis, queue_manager, and job_id' do
      job = job_class.new(queue_name: 'critical')

      expect(job.instance_variable_get(:@redis)).to eq(redis_mock)
      expect(job.instance_variable_get(:@queue_manager)).to eq(queue_manager_double)
      expect(job.job_id).to eq('123-uuid')
    end

    it 'uses default queue name and redis if none provided' do
      job_class.new

      expect(Jobkiq::QueueManagement::QueueManager)
        .to have_received(:new).with(queue_name: 'default', redis: redis_mock, tags_locker: nil)
    end
  end

  describe '#perform' do
    it 'raises NotImplementedError' do
      job = job_class.new
      expect { job.perform }.to raise_error(NotImplementedError)
    end
  end

  describe '#perform_async' do
    let(:job) { job_class.new }

    it 'assigns tags, enqueues the job, and closes redis' do
      expect(redis_mock).to receive(:close)

      result = job.perform_async(tags: %w[a b])

      expect(result).to eq(job)
      expect(job.tags).to eq(%w[a b])
      expect(queue_manager_double).to have_received(:enqueue).with(
        hash_including(
          'class' => job_class.name,
          'job_id' => '123-uuid',
          'tags' => %w[a b]
        )
      )
    end

    it 'ensures redis is closed even if enqueue raises error' do
      expect(redis_mock).to receive(:close)

      allow(queue_manager_double).to receive(:enqueue).and_raise('fail')

      expect { job.perform_async(tags: %w[x]) }.to raise_error('fail')
    end
  end

  describe '#build_job_attrs (private)' do
    let(:job) { job_class.new }

    it 'returns a hash with class, job_id, and stringified tags' do
      attrs = job.send(:build_job_attrs, tags: %i[a b])
      expect(attrs).to eq(
        'class' => job_class.name,
        'job_id' => '123-uuid',
        'tags' => %w[a b]
      )
    end
  end

  describe '#stringify_tags (private)' do
    let(:job) { job_class.new }

    it 'converts all tags to strings' do
      expect(job.send(:stringify_tags, [1, :test, 'x'])).to eq(%w[1 test x])
    end

    it 'raises error if tags is not an array' do
      expect { job.send(:stringify_tags, 'not-array') }
        .to raise_error(StandardError, 'Tags shoud be in array')
    end
  end
end
