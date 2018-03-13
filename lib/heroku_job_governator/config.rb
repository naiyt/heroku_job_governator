class InvalidHerokuGovernatorConfigError < StandardError
  def initialize(msg)
    super
  end
end

module HerokuJobGovernator
  class Config
    attr_accessor :queue_adapter, :workers, :default_worker
    REQUIRED_SETTINGS = %i[queue_adapter workers default_worker].freeze
    REQUIRED_WORKER_SETTINGS = %i[workers_min workers_max max_enqueued_per_worker queue_name].freeze
    SUPPORTED_ADAPTERS = [
      HerokuJobGovernator::DELAYED_JOB,
      HerokuJobGovernator::SIDEKIQ,
      HerokuJobGovernator::RESQUE,
    ].freeze

    def validate!
      errors = []

      missing_settings = REQUIRED_SETTINGS.select { |setting| send(setting).nil? }
      errors << "Missing required settings: #{missing_settings.join(', ')}" if missing_settings.any?

      errors << "workers incorrectly formatted. See README for configuration details." unless valid_workers?

      unless queue_adapter.nil? || SUPPORTED_ADAPTERS.include?(queue_adapter.to_sym)
        errors << "Unsupported queue_adaptor. Must be one of: #{SUPPORTED_ADAPTERS.join(', ')}"
      end

      if errors.any?
        raise InvalidHerokuGovernatorConfigError, "Heroku Config problems: #{errors.join('; ')}"
      end

      true
    end

    private

    def valid_workers?
      return true if workers.nil?
      return false unless workers.is_a?(Hash)
      workers.all? do |_k, v|
        v.is_a?(Hash) && v.keys.sort == REQUIRED_WORKER_SETTINGS.sort
      end
    end
  end
end
