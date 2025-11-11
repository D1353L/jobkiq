# spec/jobkiq/fetcher_spec.rb
# frozen_string_literal: true

require 'spec_helper'
require 'mock_redis'
require 'json'

RSpec.describe Jobkiq::Fetcher do
  let(:redis_mock) { MockRedis.new }
  let(:queue_locker) { instance_double('Jobkiq::QueueManagement::QueueLocker') }
  let(:tags_locker) { instance_double('Jobkiq::QueueManagement::TagsLocker') }
  let(:queue_name) { 'default' }
  let(:fetcher) do
    described_class.new(
      queue_name: queue_name,
      redis: redis_mock,
      queue_locker: queue_locker,
      tags_locker: tags_locker
    )
  end

  let(:job_attrs) do
    {
      'class' => 'MyJob',
      'job_id' => '123',
      'tags' => %w[tag1 tag2],
      'args' => []
    }
  end
  let(:job_json) { job_attrs.to_json }

  before do
    allow(queue_locker).to receive(:try_lock).and_return(true)
    allow(queue_locker).to receive(:release)
    allow(tags_locker).to receive(:tags_locked?).and_return(false)
    allow(tags_locker).to receive(:lock)
  end

  describe '#claim_next_job' do
    context 'when queue lock fails' do
      it 'returns nil' do
        allow(queue_locker).to receive(:try_lock).and_return(false)
        expect(fetcher.claim_next_job).to be_nil
      end
    end

    context 'when no jobs are in the queue' do
      it 'returns nil and releases the lock' do
        allow(redis_mock).to receive(:zrange).and_return([])
        expect(queue_locker).to receive(:release)
        expect(fetcher.claim_next_job).to be_nil
      end
    end

    context 'when jobs exist in the queue' do
      before do
        allow(redis_mock).to receive(:zrange).and_return([job_json])
        allow(redis_mock).to receive(:zrem).and_return(1)
      end

      it 'claims a job and locks its tags' do
        claimed = fetcher.claim_next_job
        expect(claimed).to eq(job_attrs)
        expect(tags_locker).to have_received(:lock).with(tags: job_attrs['tags'], job_id: job_attrs['job_id'])
        expect(queue_locker).to have_received(:release)
      end

      it 'returns nil if tags are locked' do
        allow(tags_locker).to receive(:tags_locked?).and_return(true)
        expect(fetcher.claim_next_job).to be_nil
      end

      it 'returns nil if job is not removed from Redis' do
        allow(redis_mock).to receive(:zrem).and_return(false)
        expect(fetcher.claim_next_job).to be_nil
      end
    end
  end

  describe 'private #find_and_claim_next_job' do
    it 'returns nil if no eligible job in multiple batches' do
      allow(redis_mock).to receive(:zrange).and_return([job_json], [])
      allow(tags_locker).to receive(:tags_locked?).and_return(true)
      result = fetcher.send(:find_and_claim_next_job)
      expect(result).to be_nil
    end
  end

  describe 'private #fetch_batch' do
    it 'fetches correct range from redis' do
      expect(redis_mock).to receive(:zrange).with(fetcher.instance_variable_get(:@queue_key), 0, 9).and_return([])
      fetcher.send(:fetch_batch, 0)
    end
  end

  describe 'private #find_eligible_job' do
    it 'returns nil if all jobs have locked tags' do
      allow(tags_locker).to receive(:tags_locked?).and_return(true)
      result = fetcher.send(:find_eligible_job, [job_json])
      expect(result).to be_nil
    end

    it 'claims first job with unlocked tags' do
      allow(redis_mock).to receive(:zrem).and_return(1)
      allow(tags_locker).to receive(:tags_locked?).and_return(false)
      result = fetcher.send(:find_eligible_job, [job_json])
      expect(result).to eq(job_attrs)
    end
  end
end
