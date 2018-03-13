module HerokuJobGovernator
  module Interfaces
    class DelayedJob < HerokuJobGovernator::Interfaces::Interface
      def self.enqueued_jobs(queue)
        queues = [queue]
        # If you don't specify a queue DJ just leaves the queue column nil
        queues << nil if queue == HerokuJobGovernator.config.default_worker
        Delayed::Job.where(queue: queues, failed_at: nil).count
      end
    end
  end
end
