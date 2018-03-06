require "singleton"
require "platform-api"

module HerokuJobGovernator
  class Governor
    include Singleton

    def scale_up(queue, num_enqueued)
      return unless Rails.env.production?
      workers = current_worker_count(queue)
      required = calculate_required_workers(queue, num_enqueued)
      scale_workers(queue, required) if workers < required
    rescue => e # rubocop:disable Style/RescueStandardError
      Rails.logger.info("Error scaling #{queue} up: #{e.message}")
      Rails.logger.info(e.backtrace)
    end

    def scale_down(queue, num_enqueued)
      return unless Rails.env.production?
      # Don't scale down if there are any running jobs, because we don't know what dyno it's running on
      return if num_enqueued > 0
      workers = current_worker_count(queue)
      required = calculate_required_workers(queue, num_enqueued)
      scale_workers(queue, required) if workers > required
    rescue => e # rubocop:disable Style/RescueStandardError
      Rails.logger.info("Error scaling #{queue} down: #{e.message}")
      Rails.logger.info(e.backtrace)
    end

    def scale_workers(queue, count)
      Rails.logger.info("Scaling #{queue} to #{count} workers")
      heroku_api.formation.update(app_name, queue, quantity: count)
    end

    def current_worker_count(queue)
      heroku_api.formation.info(app_name, queue)["quantity"]
    end

    def calculate_required_workers(queue, num_enqueued)
      required = (num_enqueued.to_f / HerokuJobGovernator.config.queues[queue][:max_enqueued_per_worker]).ceil
      max_workers = HerokuJobGovernator.config.queues[queue][:workers_max]
      min_workers = HerokuJobGovernator.config.queues[queue][:workers_min]
      return max_workers if required > max_workers
      return min_workers if required < min_workers
      required
    end

    def app_name
      ENV["HEROKU_APP_NAME"]
    end

    def heroku_api
      @heroku_api ||= PlatformAPI.connect(ENV["HEROKU_API_KEY"])
    end
  end
end
