class Railtie < Rails::Railtie
  config.redis_prometheus = ActiveSupport::OrderedOptions.new
  config.redis_prometheus.ignored_urls = ["/metrics/#{ENV["REDIS_PROMETHEUS_TOKEN"]}"]

  initializer "redis_prometheus.configure_rails_initialization" do |app|
    app.middleware.insert_before 0, RedisPrometheus::Middleware
  end
end
