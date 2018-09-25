# RedisPrometheus

After realising all the current gem solutions for Rails + Prometheus only report stats for the current process (meaning your stats will differ on every scrape), we wrote this gem that uses Redis as a shared data store.

**IMPORTANT:** This gem has no tests yet and is brand new, it was written for our internal needs and has been open-sourced under the MIT licence, but it DEFINITELY comes with zero warranty at all, including that it will either work and won't open your site up to hackers!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_prometheus'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install redis_prometheus
```

## Usage

You then need to configure two ENVironment variables (because we play nicely with 12 Factor Apps) outside of your app or in a `.env` file if you use Foreman/etc:

```
REDIS_PROMETHEUS_SERVICE=...
REDIS_PROMETHEUS_TOKEN=...
```

The `REDIS_PROMETHEUS_TOKEN` is just appended to the `/metrics` URL that this gem responds on, so if you set it as 123, you should configure Prometheus to scrape /metrics/123. This is in lieu of authentication, just to make the URL a little harder to guess.

The `REDIS_PROMETHEUS_SERVICE` is just a label for this application, so if you have multiple applications reporting in to the same Prometheus you can separate them.

If you have any paths that you want to ignore stats for, you can set them in `config/application.rb` like this:

```
config.redis_prometheus.ignored_urls += %w{/status /ping}
```

After that, configure Prometheus to scrape your URL and it will automatically report a Histogram of response times with URLs, any UUIDs in the URL will be replaced with a token so they share a URL.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andyjeffries/redis_prometheus.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

