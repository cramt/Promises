require "Promises/version"

module Promises
  class Error < StandardError; end

end

class Promise
  def pending?
    true
  end
end
