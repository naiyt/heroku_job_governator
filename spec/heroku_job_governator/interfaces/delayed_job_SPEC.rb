require "spec_helper"

RSpec.describe HerokuJobGovernator::Interfaces::DelayedJob do
  let(:subject) { HerokuJobGovernator::Interfaces::DelayedJob.new }

  describe "#enqueued_jobs" do
    let(:result_double) { double(:result) }

    it "queries for all unfailed Delayed::Jobs in the given queue" do
      # TODO: might be worth setting up an actual test db so we don't have to mock all this
      expect(Delayed::Job).to receive(:where).with(queue: [:critical], failed_at: nil).and_return(result_double)
      expect(result_double).to receive(:count).and_return(1)
      expect(subject.enqueued_jobs(:critical)).to eq(1)
    end

    context "queue is the default queue" do
      before do
        HerokuJobGovernator.configure do |config|
          config.queue_adapter = :delayed_job
          config.default_queue = :worker
          config.queues = {
            worker: {
              workers_min: 1,
              workers_max: 5,
              max_enqueued_per_worker: 5,
            },
          }
        end
      end

      it "includes nil in the queue query" do
        expect(Delayed::Job).to receive(:where).with(queue: [:worker, nil], failed_at: nil).and_return(result_double)
        expect(result_double).to receive(:count).and_return(1)
        expect(subject.enqueued_jobs(:worker)).to eq(1)
      end
    end
  end
end
