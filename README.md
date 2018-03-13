
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
  config.default_worker = :worker
  config.workers = {
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

- `queue_adapter` - this is one of the supported queue_adapters
- `default_worker` - this is the default worker used when a specific job queue is not specified
- `workers` - a hash of workers. Each must be given:
  - `workers_min` the minimum number of dynos that the worker will be scaled too
  - `workers_max` the max number of dynos that the worker will be scaled too,
  - `max_enqueued_per_worker` the max number of jobs enqueued before a new worker is spun up
  - `queue_name` the actual queue name used by the job adapter. (e.g., if you are starting this worker with a resque command of `bundle exec rake environment resque:work QUEUE=critical` this should be set as `critical`)

The gem will determine when to scale up based on (current number of enqueued jobs / `max_enqueued_per_worker`), rounded up. For example:

- 10 enqueued jobs
- `max_enqueued_per_worker` of 6

(10 / 6) = 1.67, rounded up to `2`

So the dyno will be scaled to 2 workers.

Since there is no easy mechanism to determine which dyno a given job is running on, scaling down will *only happen when there are no more enqueued jobs*.

### Adapters

#### ActiveJob

If using ActiveJob you must still set your `queue_adapter` correctly (e.g., `:delayed_job` or `:sidekiq`). Then you add this mixin to your `ActiveJob` class: `include HerokuJobGovernator::Hooks::ActiveJob`

Example:

```ruby
class MyCoolJob < ActiveJob::Base
  include HerokuJobGovernator::Hooks::ActiveJob

  def perform
    puts "I'm performing a cool job"
  end
end
```

### DelayedJob

DelayedJob can either be used on its own or in conjunction with `ActiveJob` using the instructions above. Either way, just set your `queue_adapter` to `:delayed_job`.

### Resque

Set the `queue_adapter` to `:delayed_job` and in your job class add `extend HerokuJobGovernator::Hooks::Resque`. Usage with `ActiveJob` should work as normal.

If you are setting the queue via the `@queue` variable it should work as expected. If you are using `enqueue_to`, you must also pass the `queue` name in the args. Example:

```ruby
  queue_name = select_queue(migration)
  job_id = Resque.enqueue_to(queue_name, self, { 'queue' => queue_name })
```

This is necessary because Resque does not pass the queue to the hooks.

### Sidekiq

Currently you can only use Sidekiq with `ActiveJob`. Follow the instructions for using `ActiveJob` and set your `queue_adapter` to `:sidekiq`.

Given how sidekiq works you likely will get more bang for you buck by scaling the number of threads each worker utilizes rather than spinning up a bunch of extra workers. (Too many workers and threads and you may run into database connection limits anyway). However, you may still see some good benefits by setting your `workers_min` to 0 and your `workers_max` to 1. That way you're only running the workers when jobs need to be processed. Keep in mind that since the worker needs to be kept up to wait for any jobs in `scheduled` or `retries` you may end up having workers enabled for longer than you expected if you have either of those scheduled for a longer period in the future.


### Scaling With Rake Tasks

Generally the jobs should be able to scale the workers themselves. But if there was ever a problem (e.g., the Heroku API was down or a worker was restarted while trying to scale) that could get missed. To get around that there are rake tasks that you can run to scale on a scheduled basis:

`bundle exec rake heroku_job_governator:scale_down`

`bundle exec rake heroku_job_governator:scale_up`

## Development

TODO - fill this out

## TODOS

???

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
