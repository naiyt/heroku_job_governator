module HerokuJobGovernator
  module Hooks
    class DelayedJob < ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.after(:enqueue) do |job, *args, &block|
          HerokuJobGovernator::Governor.instance.scale_up(queue(job.queue))
        end

        lifecycle.after(:perform) do |job, *args, &block|
          HerokuJobGovernator::Governor.instance.scale_down(queue(args[0].queue))
        end

        lifecycle.after(:failure) do |job, *args, &block|
          HerokuJobGovernator::Governor.instance.scale_down(queue(args[0].queue))
        end
      end

      def self.queue(queue)
        (queue || HerokuJobGovernator.config.default_queue).to_sym
      end
    end
  end
end

Delayed::Worker.plugins << HerokuJobGovernator::Hooks::DelayedJob
