require "singleton"
require "platform-api"

module HerokuJobGovernator
  class Governor
    include Singleton

    def scale_up(queue, num_enqueued)
      return unless Rails.env.production?
      worker = get_worker(queue)
      workers = current_worker_count(worker)
      required = calculate_required_workers(worker, num_enqueued)
      scale_workers(worker, required) if workers < required
    rescue => e # rubocop:disable Style/RescueStandardError
      Rails.logger.info("Error scaling #{worker} up: #{e.message}")
      Rails.logger.info(e.backtrace)
    end

    def scale_down(queue, num_enqueued)
      return unless Rails.env.production?
      # Don't scale down if there are any running jobs, because we don't know what dyno it's running on
      return if num_enqueued > 0
      worker = get_worker(queue)
      workers = current_worker_count(worker)
      required = calculate_required_workers(worker, num_enqueued)
      scale_workers(worker, required) if workers > required
    rescue => e # rubocop:disable Style/RescueStandardError
      Rails.logger.info("Error scaling #{worker} down: #{e.message}")
      Rails.logger.info(e.backtrace)
    end

    def scale_workers(worker, count)
      Rails.logger.info("Scaling #{worker} to #{count} workers")
      heroku_api.formation.update(app_name, worker, quantity: count)
    end

    def current_worker_count(worker)
      heroku_api.formation.info(app_name, worker)["quantity"]
    end

    def calculate_required_workers(worker, num_enqueued)
      required = (num_enqueued.to_f / HerokuJobGovernator.config.workers[worker][:max_enqueued_per_worker]).ceil
      max_workers = HerokuJobGovernator.config.workers[worker][:workers_max]
      min_workers = HerokuJobGovernator.config.workers[worker][:workers_min]
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

    def get_worker(queue)
      worker_info = HerokuJobGovernator.config.workers.find { |k, v| v[:queue_name].to_sym == queue.to_sym }
      worker_info.nil? ? HerokuJobGovernator.config.default_worker : worker_info[0]
    end
  end
end
