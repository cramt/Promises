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
    new start_value: value
  end

  def self.reject(reason)
    new start_reason: reason
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
      promises.each_with_index {|promise, index|
        promise.then(proc {|value|
          values[index] = value
          i -= 1
          if i == 0 && !stopped
            resolve.call(values)
          end
        }, proc {|reason|
          stopped = true
          reject.call(reason)
        })
      }
    end
  end

  def self.race(promises)
    Promise.new do |resolve, reject|
      finished = false
      promises.each {|promise|
        promise.then(proc {|value|
          unless finished
            resolve.call(value)
            finished = true
          end
        }, proc {|reason|
          unless finished
            reject.call(reason)
            finished = true
          end
        })
      }
    end
  end

  def self.all_settled(promises)
    Promise.new do |resolve, _|
      resolve.call(promises.map {|promise|
        begin
           {
            value => promise.await,
            state => "fulfilled"
          }
        rescue Promises::RejectedError => e
          return {
            reason => e.message,
            state => "rejected"
          }
        end
      })
    end
  end

  def initialize(start_value: nil, start_reason: nil, &block)
    @state = :pending
    return update_state(start_value, start_reason) unless block_given?

    @thread = Thread.new do
      wait_thread = Thread.new {sleep}
      block.call(proc {|value|
        @value = value
        @state = :fulfilled
        wait_thread.terminate
      }, proc {|reason|
        @reason = reason
        @state = :rejected
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

  def finally(&block)
    self.then {|value|
      block.call
      value
    }
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
