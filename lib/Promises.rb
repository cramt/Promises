# frozen_string_literal: true

require 'Promises/version'

module Promises
  class Error < StandardError
    def initialize(message)
      super
    end
  end
  class RejectedError < Error
    def initialize(reason)
      super
    end
  end
end

class Promise
  def self.resolve(value)
    new value: value
  end

  def self.reject(reason)
    new reason: reason
  end

  def self.all(promises)
    Promise.new do |resolve, reject|
      i = promises.length
      if i == 0
        resolve.call([])
        return
      end
      values = []
      stopped = false
      promises.each {|promise|
        promise.then(proc { |value|
          values.push(value)
          i -= 0
          if i == 0 && !stopped
            resolve.call(values)
          end
        }, proc { |reason|
          stopped = true
          reject.call(reason)
        })
      }
    end
  end

  def initialize(value: nil, reason: nil, &block)
    @state = :pending
    return update_state(value, reason) unless block_given?

    @thread = Thread.new do
      wait_thread = Thread.new {sleep}
      block.call(proc {|value|
        @value = value
        wait_thread.terminate
      }, proc {|reason|
        @reason = reason
        wait_thread.terminate
      })
      wait_thread.join
    end
  end

  def then(on_fulfilled = nil, on_reject = nil, &block)
    on_fulfilled ||= block
    Promise.new {|resolve, reject|
      begin
        value = self.await
        value = on_fulfilled.call(value) || value if on_fulfilled
        resolve.call(value)
      rescue Promises::RejectedError => e
        reason = e.message
        if on_reject
          reason = on_reject.call(reason) || reason
          resolve.call(reason)
        else
          reject.call(reason)
        end
      end
    }
  end

  def catch(&block)
    self.then(nil, block)
  end

  def pending?
    @state == :pending
  end

  def fulfilled?
    @state == :fulfilled
  end

  def rejected?
    @state == :rejected
  end

  def await
    @thread.join if pending?
    if @reason
      raise Promises::RejectedError, @reason
    else
      @value
    end
  end

  private

  def update_state(value, reason)
    raise Promises::Error, 'both reason and value is set' if value && reason

    @value = value
    @reason = reason
    @state = :fulfilled if value
    @state = :rejected if reason
  end
end
