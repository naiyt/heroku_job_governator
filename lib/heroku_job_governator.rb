require_relative "heroku_job_governator/constants"
require_relative "heroku_job_governator/governor"
require_relative "heroku_job_governator/interfaces/interface"
require_relative "heroku_job_governator/interfaces/delayed_job"
require_relative "heroku_job_governator/interfaces/sidekiq"
require_relative "heroku_job_governator/interfaces/resque"
require_relative "heroku_job_governator/config"
require_relative "heroku_job_governator/hooks/active_job"
require_relative "heroku_job_governator/hooks/resque"

module HerokuJobGovernator
  def self.configure
    yield config

    config.validate!

    if config.queue_adapter.to_sym == DELAYED_JOB
      require_relative "heroku_job_governator/hooks/delayed_job"
    end
  end

  def self.config
    @config ||= HerokuJobGovernator::Config.new
  end

  def self.adapter_interface
    case HerokuJobGovernator.config.queue_adapter.to_sym
    when HerokuJobGovernator::DELAYED_JOB
      HerokuJobGovernator::Interfaces::DelayedJob
    when HerokuJobGovernator::SIDEKIQ
      HerokuJobGovernator::Interfaces::Sidekiq
    when HerokuJobGovernator::RESQUE
      HerokuJobGovernator::Interfaces::Resque
    end
  end
end
