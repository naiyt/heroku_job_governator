module HerokuJobGovernator
  module Hooks
    module ActiveJob
      def self.included(base)
        base.class_eval do
          after_enqueue do |job|
            queue_name = get_queue_name(job)
            HerokuJobGovernator::Governor.instance.scale_up(
              queue_name,
              HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
            )
          end

          around_perform do |job, block|
            queue_name = get_queue_name(job)
            begin
              HerokuJobGovernator::Governor.instance.scale_up(
                queue_name,
                HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
              )
              block.call
            ensure
              HerokuJobGovernator::Governor.instance.scale_down(
                queue_name,
                HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
              )
            end
          end

          after_perform do |job|
            queue_name = get_queue_name(job)
            HerokuJobGovernator::Governor.instance.scale_down(
              queue_name,
              HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
            )
          end

          def get_queue_name(job)
            queue_name = job.queue_name
            queue_name = HerokuJobGovernator.config.default_worker if queue_name.to_sym == :default
            queue_name.to_sym
          end
        end
      end
    end
  end
end
