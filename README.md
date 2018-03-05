
# HerokuJobGovernator

Scale Heroku worker dynos based on queue length.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heroku_job_governator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install heroku_job_governator

## Configuration

The following environment variables must be set:

* `HEROKU_API_KEY`
* `HEROKU_APP_NAME`

The gem can then be configured by creating an initializer in `config/initializers` called `heroku_job_governator.rb`.

Configuration example:

```ruby
HerokuJobGovernator.configure do |config|
  config.queue_adapter = :delayed_job
  config.default_queue = :worker
  config.queues = {
    worker: {
      workers_min: 0,
      workers_max: 2,
      max_enqueued_per_worker: 5,
    },
    critical: {
      workers_min: 0,
      workers_max: 2,
      max_enqueued_per_worker: 3,
    }
  }
end
```

Options breakdown:

- `queue_adapter` - this is one of the supported queue_adapters (currently only :delayed_job)
- `default_queue` - this is the default worker queue used when a specific job queue is not specified
- `queues` - a hash of workers. Each must be given: `workers_min` (the minimum number of dynos that the worker will be scaled too), `workers_max` (the max number of dynos that the worker will be scaled too), and `max_enqueued_per_worker`

The gem will determine when to scale up based on (current number of enqueued jobs / max_enqueued_per_worker), rounded up. For example:

- 10 enqueued jobs
- `max_enqueued_per_worker` of 6

(10 / 6) = 1.67, rounded up to `2`

So the dyno will be scaled to 2 workers.

Since there is no easy mechanism to determine which dyno a given job is running on, scaling down will *only happen when there are no more enqueued jobs*.

### ActiveJob

If using ActiveJob you must still set your `queue_adapter` correctly (e.g., `:delayed_job` or `:sidekiq`). Then you add this mixin to your `ActiveJob` class: `include HerokuJobGovernator::Hooks::ActiveJob`

### Scaling With Rake Tasks

Generally the jobs should be able to scale the workers themselves. But if there was ever a problem (e.g., the Heroku API was down or a worker was restarted while trying to scale) that could get missed. To get around that there are rake tasks that you can run to scale on a scheduled basis:

`bundle exec rake heroku_job_governator:scale_down`

`bundle exec rake heroku_job_governator:scale_up`

## Development

TODO - fill this out

## TODOS

Adapters to add:

- ActiveJob
- Sidekiq
- Resque

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
