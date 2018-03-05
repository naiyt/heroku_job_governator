module HerokuJobGovernator
  module Interfaces
    class Sidekiq < HerokuJobGovernator::Interfaces::Interface
      def enqueued_jobs(queue)
        queued_count = ::Sidekiq::Queue.new(queue).count
        scheduled_count = ::Sidekiq::ScheduledSet.new.count { |s| s.queue == queue }
        retries_count = ::Sidekiq::RetrySet.new.count { |r| r.queue == queue }
        running_count = ::Sidekiq::Workers.new.count { |_p, _t, w| w["queue"].to_sym == queue }

        queued_count + running_count + scheduled_count + retries_count
      end
    end
  end
end
