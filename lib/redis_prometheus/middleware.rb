require 'benchmark'

module RedisPrometheus
  class Middleware
    def initialize(app, options = {})
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] == "/metrics/#{ENV["REDIS_PROMETHEUS_TOKEN"]}"
        results(env)
      else
        trace(env) do
          @app.call(env)
        end
      end
    end

    protected

    def trace(env)
      response = nil
      duration = Benchmark.realtime { response = yield }
      record(env, response.first.to_s, duration)
      response
    end

    def results(env)
      headers = {}
      response = ""

      keys = Redis.current.keys("http_request_duration_seconds_bucket/#{ENV["REDIS_PROMETHEUS_SERVICE"]}:*")
      values = Redis.current.mget(keys)
      response << "# TYPE http_request_duration_seconds_bucket histogram\n"
      response << "# HELP http_request_duration_seconds_bucket The HTTP response duration of the Rack application.\n"
      keys.each_with_index do |key, i|
        key_parts = key.split("|")
        key_parts.shift

        data = {}
        key_parts.each do |p|
          k,v = p.split("=")
          data[k.to_sym] = v
        end
        data[:service] = ENV["REDIS_PROMETHEUS_SERVICE"]

        next if Rails.application.config.redis_prometheus.ignored_urls.include?(data[:url])

        response << "http_request_duration_seconds_bucket{"
        response << data.map {|k,v| "#{k}=\"#{v}\""}.join(",")
        response << "} #{values[i].to_f}\n"
      end

      response << "# TYPE http_request_duration_seconds_count counter\n"
      response << "# HELP http_request_duration_seconds_count The total number of HTTP requests handled by the Rack application.\n"
      requests = Redis.current.get("http_request_duration_seconds_count/#{ENV["REDIS_PROMETHEUS_SERVICE"]}") || 0
      response << "http_request_duration_seconds_count{service=\"#{ENV["REDIS_PROMETHEUS_SERVICE"]}\"} #{requests.to_f}\n"

      response << "# TYPE http_request_duration_seconds_sum counter\n"
      response << "# HELP http_request_duration_seconds_sum The total number of seconds spent processing HTTP requests by the Rack application.\n"
      requests = Redis.current.get("http_request_duration_seconds_sum/#{ENV["REDIS_PROMETHEUS_SERVICE"]}") || 0
      response << "http_request_duration_seconds_sum{service=\"#{ENV["REDIS_PROMETHEUS_SERVICE"]}\"} #{requests.to_f}\n"

      response << "# TYPE http_request_client_errors_counter counter\n"
      response << "# HELP http_request_client_errors_counter The total number of HTTP errors return by the Rack application.\n"
      requests = Redis.current.get("http_request_client_errors_counter/#{ENV["REDIS_PROMETHEUS_SERVICE"]}") || 0
      response << "http_request_client_errors_counter{service=\"#{ENV["REDIS_PROMETHEUS_SERVICE"]}\"} #{requests.to_f}\n"

      response << "# TYPE http_request_server_errors_counter counter\n"
      response << "# HELP http_request_server_errors_counter The total number of HTTP errors return by the Rack application.\n"
      requests = Redis.current.get("http_request_server_errors_counter/#{ENV["REDIS_PROMETHEUS_SERVICE"]}") || 0
      response << "http_request_server_errors_counter{service=\"#{ENV["REDIS_PROMETHEUS_SERVICE"]}\"} #{requests.to_f}\n"

      headers['Content-Encoding'] = "gzip"
      headers['Content-Type'] = "text/plain"
      gzip = Zlib::GzipWriter.new(StringIO.new)
      gzip << response
      compressed_response = gzip.close.string

      [200, headers, [compressed_response]]
    end

    def record(env, code, duration)
      url = "#{env["SCRIPT_NAME"]}#{env["PATH_INFO"]}"
      return if Rails.application.config.redis_prometheus.ignored_urls.include?(url)

      url.gsub!(%r{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}i, "{uuid}")
      url.gsub!(%r{/\b\d+\b}i, "{id}")
      url.gsub!(":id", "{id}")

      bucket = duration_to_bucket(duration)
      Redis.current.incr("http_request_duration_seconds_bucket/#{ENV["REDIS_PROMETHEUS_SERVICE"]}|url=#{url}|le=#{bucket}")
      Redis.current.incr("http_request_duration_seconds_count/#{ENV["REDIS_PROMETHEUS_SERVICE"]}")
      Redis.current.incrbyfloat("http_request_duration_seconds_sum/#{ENV["REDIS_PROMETHEUS_SERVICE"]}", duration)
      if code.to_i >= 400 && code.to_i <= 499
        Redis.current.incr("http_request_client_errors_counter/#{ENV["REDIS_PROMETHEUS_SERVICE"]}")
      end
      if code.to_i >= 500 && code.to_i <= 599
        Redis.current.incr("http_request_server_errors_counter/#{ENV["REDIS_PROMETHEUS_SERVICE"]}")
      end
    end

    def duration_to_bucket(duration)
      return case
      when duration <= 0.005
        "0.005"
      when duration <= 0.01
        "0.01"
      when duration <= 0.025
        "0.025"
      when duration <= 0.05
        "0.05"
      when duration <= 0.1
        "0.1"
      when duration <= 0.25
        "0.25"
      when duration <= 0.5
        "0.5"
      when duration <= 1
        "1"
      when duration <= 2.5
        "2.5"
      when duration <= 5
        "5"
      when duration <= 10
        "10"
      else
        "+Inf"
      end
    end
  end
end
