module Nominatim
  class Monitor
    ThresholdError = Class.new(RuntimeError)

    def initialize(downtime: 60, threshold: 5)
      @downtime  = downtime
      @threshold = threshold

      reset
    end

    def execute
      raise ThresholdError if broken?

      begin
        yield.tap do
          reset
        end
      rescue
        @failure_count += 1
        @failure_clock  = Time.now if @failure_count == @threshold

        raise
      end
    end

    protected

    def broken?
      if @failure_count == @threshold
        if Time.now - @failure_clock < @downtime
          true
        else
          reset
          false
        end
      end
    end

    def reset
      @failure_count = 0
      @failure_clock = 0
    end
  end
end
