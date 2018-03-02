require "spec_helper"

RSpec.describe HerokuJobGovernator::Config do
  let(:subject) { HerokuJobGovernator::Config.new }

  describe "#validate!" do
    it "raises an exception if it is missing a required setting" do
      expect {
        subject.validate!
      }.to raise_exception(InvalidHerokuGovernatorConfigError)
    end

    it "raises an exception if the queues are formatted badly" do
      subject.queue_adapter = :delayed_job
      subject.default_queue = :worker
      subject.queues = "blah"

      expect {
        subject.validate!
      }.to raise_exception(InvalidHerokuGovernatorConfigError)
    end

    it "raises an exception if specifying an unsupported queue adaptor" do
      subject.queue_adapter = :cool_new_adapter
      subject.default_queue = :worker
      subject.queues = {
        worker: {
          workers_min: 0,
          workers_max: 3,
          max_enqueued_per_worker: 2,
        },
      }

      expect {
        subject.validate!
      }.to raise_exception(InvalidHerokuGovernatorConfigError)
    end

    it "returns true if there are no validation issues" do
      subject.queue_adapter = :delayed_job
      subject.default_queue = :worker
      subject.queues = {
        worker: {
          workers_min: 0,
          workers_max: 3,
          max_enqueued_per_worker: 2,
        },
      }

      expect { subject.validate! }.to_not raise_exception
    end
  end
end
