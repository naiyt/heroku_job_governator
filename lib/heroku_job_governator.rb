require_relative "heroku_job_governator/constants"
require_relative "heroku_job_governator/governor"
require_relative "heroku_job_governator/interfaces/interface"
require_relative "heroku_job_governator/interfaces/delayed_job"
require_relative "heroku_job_governator/config"
require_relative "heroku_job_governator/hooks/active_job"

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
end
