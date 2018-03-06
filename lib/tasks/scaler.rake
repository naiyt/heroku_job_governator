namespace :heroku_job_governator do
  desc "Scale workers down if necessary"
  task scale_down: :environment do
    queues = HerokuJobGovernator.config.queues.keys
    queues.each do |queue|
      puts "Attempting to scale down #{queue}"
      HerokuJobGovernator::Governor.instance.scale_down(queue, HerokuJobGovernator.adapter_interface.enqueued_jobs(queue))
    end
  end

  desc "Scale workers up if necessary"
  task scale_up: :environment do
    queues = HerokuJobGovernator.config.queues.keys
    queues.each do |queue|
      puts "Attempting to scale up #{queue}"
      HerokuJobGovernator::Governor.instance.scale_up(queue, HerokuJobGovernator.adapter_interface.enqueued_jobs(queue))
    end
  end
end
