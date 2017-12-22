module GovernedJob 
  module ResqueHooks
    def after_perform_scale_down(*args)
      puts "************************************************** after perform"
      scale_down(queue(args))
    end

    def on_failure_scale_down(exception, *args)
      puts "************************************************** on failure"
      scale_down(queue(args))
    end
    
    def after_enqueue_scale_up(*args)
      puts "&&"
      puts args
      puts "&&"
      debugger
      puts "************************************************** after enqueue"
      scale_up(queue(args))
    end
    
    def queue(*args)
      queue = args['queue'] || Resque.queue_from_class(self)
      raise "Queue not defined, pass 'queue' to job arguments or define queue method or variable in class" unless queue
      queue
    end
  end
end