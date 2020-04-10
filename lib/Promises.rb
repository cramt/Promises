require "Promises/version"

module Promises
  class Error < StandardError
    def initialize

    end
  end
end

class Promise
  @value
  @thread
  @reason

  def initialize(&block)
    @thread = Thread.new {
      wait_thread = Thread.new {sleep}
      block.call(proc {|value|
        @value = value
        wait_thread.terminate
      }, proc {|reason|
        @reason = reason
        wait_thread.terminate
      })
      wait_thread.join
    }
  end

  def pending?
    true
  end

  def await
    @thread.join
    if @reason
      raise @reason
    else
      return @value
    end
  end
end
