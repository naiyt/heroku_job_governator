module GovernedJob 
  module ResqueHooks
    def after_perform_scale_down(*args)
      puts "************************************************** after perform"
      # scale_down(queue(args))
      scale_down('worker_umich_qa')
    end

    def on_failure_scale_down(exception, *args)
      puts "************************************************** on failure"
      # scale_down(queue(args))
      scale_down('worker_umich_qa')
    end
    
    def after_enqueue_scale_up(*args)
      puts "&&"
      puts args
      puts "&&"
      puts "************************************************** after enqueue"
      begin
        q = queue(args)
        puts "****(queue) #{q}"
      rescue Exception => e
        puts "*****ERRROR"
        puts e.message
        puts e.backtrace
        puts "*****END ERRROR"
      end
      scale_up('worker_umich_qa')
    end
    
    def queue(*args)
      queue = args['queue'] || Resque.queue_from_class(self)
      raise "Queue not defined, pass 'queue' to job arguments or define queue method or variable in class" unless queue
      queue
    end
  end
end