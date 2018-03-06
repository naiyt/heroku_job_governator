module HerokuJobGovernator
  module Hooks
    class DelayedJob < ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.after(:enqueue) do |job, *args, &block|
          queue_name = queue(job.queue)
          HerokuJobGovernator::Governor.instance.scale_up(
            queue_name,
            HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
          )
        end

        lifecycle.before(:perform) do |job, *args, &block|
          queue_name = queue(args[0].queue)
          HerokuJobGovernator::Governor.instance.scale_up(
            queue_name,
            HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
          )
        end

        lifecycle.after(:perform) do |job, *args, &block|
          queue_name = queue(args[0].queue)
          HerokuJobGovernator::Governor.instance.scale_down(
            queue_name,
            HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
          )
        end

        lifecycle.after(:failure) do |job, *args, &block|
          queue_name = queue(args[0].queue)
          HerokuJobGovernator::Governor.instance.scale_down(
            queue_name,
            HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
          )
        end
      end

      def self.queue(queue)
        (queue || HerokuJobGovernator.config.default_queue).to_sym
      end
    end
  end
end

Delayed::Worker.plugins << HerokuJobGovernator::Hooks::DelayedJob
