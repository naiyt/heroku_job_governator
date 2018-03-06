module HerokuJobGovernator
  module Interfaces
    class Resque < HerokuJobGovernator::Interfaces::Interface
      def self.enqueued_jobs(queue)
        queued = ::Resque.size(queue.to_s)
        working = ::Resque.working.map(&:job).count { |j| j["queue"] == queue.to_s }
        queued + working
      end
    end
  end
end
