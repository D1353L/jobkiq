# frozen_string_literal: true

class TestJob
  include Jobkiq::Job

  def perform
    sleep(rand(0..3))
  end
end
