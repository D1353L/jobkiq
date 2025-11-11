# spec/jobkiq/worker_spec.rb
# frozen_string_literal: true

require 'spec_helper'
require 'mock_redis'

RSpec.describe Jobkiq::Worker do
  let(:redis_mock) { MockRedis.new }
  let(:queue_manager) { instance_double('Jobkiq::QueueManagement::QueueManager') }
  let(:fetcher) { instance_double('Jobkiq::Fetcher') }
  let(:logger) { instance_double('Logger', info: true, error: true) }
  let(:worker) do
    described_class.new(
      queue_name: 'default',
      redis: redis_mock,
      queue_manager: queue_manager,
      fetcher: fetcher,
      logger: logger
    )
  end

  before do
    allow(worker).to receive(:work_loop)
    allow(worker).to receive(:trap_signals)
  end

  describe '#initialize' do
    it 'sets instance variables properly' do
      expect(worker.instance_variable_get(:@redis)).to eq(redis_mock)
      expect(worker.instance_variable_get(:@queue_name)).to eq('default')
      expect(worker.instance_variable_get(:@logger)).to eq(logger)
      expect(worker.instance_variable_get(:@fetcher)).to eq(fetcher)
      expect(worker.instance_variable_get(:@queue_manager)).to eq(queue_manager)
      expect(worker.instance_variable_get(:@running)).to be true
    end
  end

  describe '#run!' do
    it 'logs start, traps signals, and calls work_loop' do
      worker.run!
      expect(logger).to have_received(:info).with('Jobkiq worker started (queue=default)')
      expect(worker).to have_received(:trap_signals)
      expect(worker).to have_received(:work_loop)
    end

    it 'rescues exceptions and logs worker crash' do
      allow(worker).to receive(:work_loop).and_raise(StandardError.new('boom'))
      worker.run!
      expect(logger).to have_received(:error).with(/Worker crashed: boom/)
    end
  end

  describe '#execute_job' do
    let(:job_class) do
      Class.new do
        include Jobkiq::Job

        def self.name
          'JobClass'
        end
      end
    end

    let(:job_attrs) do
      {
        'class' => job_class.name,
        'job_id' => '123',
        'tags' => ['tag1'],
        'args' => [1, 2]
      }
    end

    before do
      stub_const(job_class.name, job_class)
    end

    it 'instantiates job class and calls perform with args' do
      expect_any_instance_of(job_class).to receive(:perform).with(1, 2)
      worker.send(:execute_job, job_attrs)
      expect(logger).to have_received(:info).with(/Start: class=#{job_class}, job_id=123, tags=\["tag1"\]/)
    end

    it 'logs failure if job raises exception' do
      allow_any_instance_of(job_class).to receive(:perform).and_raise('job fail')
      worker.send(:execute_job, job_attrs)
      expect(logger).to have_received(:error).with(/FAILED: class=#{job_class}, job_id=123, ERROR: job fail/)
    end
  end

  describe '#finish_execution' do
    let(:job_attrs) do
      { 'class' => 'MyJob', 'job_id' => '123' }
    end

    it 'calls queue_manager handle_post_execution and logs done' do
      allow(queue_manager).to receive(:handle_post_execution)
      worker.send(:finish_execution, job_attrs)
      expect(queue_manager).to have_received(:handle_post_execution).with(job_attrs)
      expect(logger).to have_received(:info).with(/Done: class=MyJob, job_id=123/)
    end
  end

  describe '#shutdown' do
    it 'sets @running to false' do
      expect { worker.send(:shutdown) }.to change { worker.instance_variable_get(:@running) }.from(true).to(false)
    end
  end
end
