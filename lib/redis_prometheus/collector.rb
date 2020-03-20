module RedisPrometheus
  class Collector
    def self.current
      @current ||= self.new
      @current
    end

    def initialize
      @collectors = []
    end

    def stats
      out = ""
      @collectors.each do |collector|
        ret = collector.call
        out << "# TYPE #{ret[:label]} #{ret[:type]}\n"
        out << "# HELP #{ret[:label]} #{ret[:description]}.\n"

        out << "#{ret[:label]}{service=\"#{ENV["REDIS_PROMETHEUS_SERVICE"]}\"} #{ret[:data]}\n"
      end
      out
    end

    def register(&block)
      @collectors << block
    end
  end
end