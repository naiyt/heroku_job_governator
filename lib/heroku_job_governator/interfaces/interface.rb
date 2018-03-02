class NotImplentedError < StandardError
  def initialize(msg="Must be implemented in subclass")
    super
  end
end

module HerokuJobGovernator
  module Interfaces
    class Interface
      def enqueued_jobs(_queue)
        raise NotImplentedError
      end
    end
  end
end
