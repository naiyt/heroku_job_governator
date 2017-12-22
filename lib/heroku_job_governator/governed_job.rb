require 'platform-api'
require_relative "resque_hooks"
require_relative "job_governer"

module GovernedJob 
  module Governer
    @@heroku = PlatformAPI.connect(ENV['HEROKU_API_KEY'])
    @@governer = JobGoverner.governer
    
    class << self
      
      def workers(queue)
        return -1 unless authorized?
        result = @@heroku.formation.info(app_name, queue)
        result['quantity']
      end
      
      def scale_workers(quantity, queue)
        puts "Scaling workers on #{queue} to #{quantity}"
        return unless authorized?
        
        quantity = quantity.to_i
        begin
          puts "attempting heroku update"
          result = @@heroku.formation.update(app_name, queue, { quantity: quantity })
          result['quantity'] == quantity
        rescue Exception => e 
          puts "*****ERRROR"
          puts e.message
          puts e.backtrace
          puts "*****END ERRROR"
        end
      end
      
      protected

      def app_name
        ENV['HEROKU_APP_NAME']
      end
      
      
      private
      
      def authorized?
        Rails.env == "production"
      end
    end
  end
  
  def self.extended base
    base.class_eval do
      if defined?(Resque)
        extend ResqueHooks
      else
        raise "no valid job processors to govern found"
      end
    end
  end
  
  def scale_up(queue)
    puts "**************************************************"
    puts "scaling up"
    puts "**************************************************"
    Governer.scale_workers(1, queue)
  end
  
  def scale_down(queue)
    puts "**************************************************"
    puts "scaling down"
    puts "**************************************************"
    Governer.scale_workers(0, queue)
  end
  
end 