module HerokuJobGovernator
  module Hooks
    module Resque
      def after_enqueue_scale_up(*args)
        queue_name = get_queue_name(args)
        HerokuJobGovernator::Governor.instance.scale_up(
          queue_name,
          HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
        )
      end

      def before_perform_scale_up(*args)
        queue_name = get_queue_name(args)
        HerokuJobGovernator::Governor.instance.scale_up(
          queue_name,
          HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
        )
      end

      def after_perform_scale_down(*args)
        queue_name = get_queue_name(args)
        # Subtract 1 because Resque includes the currently running job
        num_enqueued = HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name) - 1
        HerokuJobGovernator::Governor.instance.scale_down(queue_name, num_enqueued)
      end

      def on_failure_scale_down(_exception, *args)
        queue_name = get_queue_name(args)
        HerokuJobGovernator::Governor.instance.scale_down(
          queue_name,
          HerokuJobGovernator.adapter_interface.enqueued_jobs(queue_name),
        )
      end

      def get_queue_name(args)
        from_args = args.is_a?(Array) && args.length > 0 ? args[0]["queue"] : nil
        (from_args || ::Resque.queue_from_class(self) || HerokuJobGovernator.config.default_queue).to_sym
      end
    end
  end
end
