module GovernedJob 
  module ActiveJobHooks
    after_perform do |job|
      scale_down(queue(args))
    end

    
    after_enqueue do |job|
      scale_up(queue(args))
    end
    
    def queue(*args)
      "TODO"
    end
  end
end