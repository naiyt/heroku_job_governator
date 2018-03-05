class InvalidHerokuGovernatorConfigError < StandardError
  def initialize(msg)
    super
  end
end

module HerokuJobGovernator
  class Config
    attr_accessor :queue_adapter, :queues, :default_queue
    REQUIRED_SETTINGS = %i[queue_adapter queues default_queue].freeze
    SUPPORTED_ADAPTERS = [HerokuJobGovernator::DELAYED_JOB, HerokuJobGovernator::SIDEKIQ].freeze

    def validate!
      errors = []

      missing_settings = REQUIRED_SETTINGS.select { |setting| send(setting).nil? }
      errors << "Missing required settings: #{missing_settings.join(', ')}" if missing_settings.any?

      errors << "queues incorrectly formatted. See README for configuration details." unless valid_queues?

      unless queue_adapter.nil? || SUPPORTED_ADAPTERS.include?(queue_adapter.to_sym)
        errors << "Unsupported queue_adaptor. Must be one of: #{SUPPORTED_ADAPTERS.join(', ')}"
      end

      if errors.any?
        raise InvalidHerokuGovernatorConfigError, "Heroku Config problems: #{errors.join('; ')}"
      end

      true
    end

    private

    def valid_queues?
      return true if queues.nil?
      return false unless queues.is_a?(Hash)
      queues.all? do |_k, v|
        v.is_a?(Hash) && v.keys == %i[workers_min workers_max max_enqueued_per_worker]
      end
    end
  end
end
