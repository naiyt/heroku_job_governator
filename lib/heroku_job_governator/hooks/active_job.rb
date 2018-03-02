module HerokuJobGovernator
  module Hooks
    module ActiveJob
      def self.included(base)
        base.class_eval do
          after_enqueue do |job|
            HerokuJobGovernator::Governor.instance.scale_up(queue(job))
          end

          around_perform do |job, block|
            begin
              block.call
            ensure
              HerokuJobGovernator::Governor.instance.scale_down(queue(job))
            end
          end

          def queue(job)
            queue_name = job.queue_name
            queue_name = HerokuJobGovernator.config.default_queue if queue_name.to_sym == :default
            queue_name.to_sym
          end
        end
      end
    end
  end
end
