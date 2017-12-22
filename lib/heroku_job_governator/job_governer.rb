require_relative "resque_governer"

module GovernedJob 
  module JobGoverner
    class << self
      
      def governer
        if defined?(Resque)
          ResqueGoverner.new
        else
          raise "no valid job processors to govern found"
        end
      end
    end
  end
end