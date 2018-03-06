module HerokuJobGovernator
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/scaler.rake"
    end
  end
end
