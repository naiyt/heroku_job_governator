require "spec_helper"

# Fake Rails
class Rails
  def self.env; end
end

RSpec.describe HerokuJobGovernator::Governor do
  let(:subject) { HerokuJobGovernator::Governor.instance }

  before do
    HerokuJobGovernator.configure do |config|
      config.queue_adapter = :delayed_job
      config.default_worker = :worker
      config.workers = {
        worker_default: {
          workers_min: 0,
          workers_max: 1,
          max_enqueued_per_worker: 2,
          queue_name: "Imma worker",
        },
      }
    end
  end

  describe "#scale_up" do
    context "not in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "does nothing" do
        expect(subject).to_not receive(:current_worker_count)
        subject.scale_up(:worker, 1)
      end
    end

    context "in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "scales the workers up if current workers is less than required" do
        allow(subject).to receive(:current_worker_count).with(:worker).and_return(2)
        allow(subject).to receive(:calculate_required_workers).with(:worker, 10).and_return(3)
        expect(subject).to receive(:scale_workers).with(:worker, 3)
        subject.scale_up(:worker, 10)
      end

      it "does nothing if workers is greater than or equal to required" do
        allow(subject).to receive(:current_worker_count).with(:worker).and_return(3)
        allow(subject).to receive(:calculate_required_workers).with(:worker, 10).and_return(3)
        expect(subject).to_not receive(:scale_workers)
        subject.scale_up(:worker, 10)
      end
    end
  end

  describe "#scale_down" do
    context "not in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "does nothing" do
        expect(subject).to_not receive(:current_worker_count)
        subject.scale_down(:worker, 10)
      end
    end

    context "in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      context "there are more workers than required" do
        let(:adapter_double) { double(:adapter) }

        before do
          allow(subject).to receive(:adapter_interface).and_return(adapter_double)
          allow(subject).to receive(:current_worker_count).with(:worker).and_return(3)
          allow(subject).to receive(:calculate_required_workers).with(:worker, anything).and_return(1)
        end

        context "there are still running jobs" do
          it "does nothing" do
            expect(subject).to_not receive(:scale_workers)
            subject.scale_down(:worker, 10)
          end
        end

        context "there are no running jobs" do
          it "scales down" do
            expect(subject).to receive(:scale_workers).with(:worker, 1)
            subject.scale_down(:worker, 0)
          end
        end
      end
    end
  end

  describe "#calculate_required_workers" do
    let(:adapter_double) { double(:adapter) }

    before do
      HerokuJobGovernator.configure do |config|
        config.queue_adapter = :delayed_job
        config.default_worker = :worker
        config.workers = {
          worker: {
            workers_min: 1,
            workers_max: 5,
            max_enqueued_per_worker: 5,
            queue_name: "Imma queue",
          },
        }
      end

      allow(subject).to receive(:adapter_interface).and_return(adapter_double)
    end

    context "required is greater than max" do
      it "returns max" do
        expect(subject.calculate_required_workers(:worker, 100)).to eq(5)
      end
    end

    context "required is less than min" do
      it "returns min" do
        expect(subject.calculate_required_workers(:worker, 0)).to eq(1)
      end
    end

    context "required is between min and max" do
      it "returns required" do
        expect(subject.calculate_required_workers(:worker, 6)).to eq(2)
      end
    end
  end
end
