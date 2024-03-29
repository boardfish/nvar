# `Nvar`

If your app relies on lots of environment secrets, onboarding's tough. New team members need to add credentials for fifty different services and configure no end of app settings through their environment. Worse still, if a merged PR introduces something new, it can lead to inconvenient and unpredictable errors. **`Nvar` helps keep your team in step** by making sure all necessary environment variables are set.

You can use `Nvar` in Ruby apps, with out-of-the-box support provided for Rails.
## Installation

Add the gem to your Gemfile and install it with `bundle add nvar`. If you're not on Rails, you'll need to make sure that `Nvar` is required with `require 'nvar'`, and then manually call `Nvar.load_all` as early as is appropriate.

It's recommended to do this by adding the following to `config/application.rb`:

```rb
require "dotenv/load" # if using in tandem with dotenv
require "nvar"

Nvar.load_all
```

## Configuration

`Nvar` is configured by way of `config/environment_variables.yml`. If you're on Rails, this file will be created for you automatically. Each key corresponds to the name of a required environment variable, and houses its configuration, all of which is optional.

```yml
REQUIRED_ENV_VAR:
  required: false # defaults to true
  type: Integer # defaults to String
  default_value: 8
  filter_from_requests: true # defaults to false
  passthrough: true # defaults to false
```

- **required** determines whether an error will be raised if the environment variable is unset during initialization.
- **type** determines which type the variable will be cast to on load.
- **default_value** decides the value of the environment variable if it's absent.
- **filter_from_requests** is potentially the most exciting of the bunch - it integrates with the `vcr` gem. If your environment variable is a secret that's used directly (e.g. in bearer token authentication), use `true`. If it's used on its own as the password for basic auth, use `alone_with_basic_auth_password`. To activate the filtering, configure `VCR` as follows:

```ruby
VCR.configure do |config|
  Nvar::EnvironmentVariable.filter_from_vcr_cassettes(config)
end
```

Now, if you use `VCR` to record a request, that credential will be hidden using `vcr`'s `#filter_sensitive_data` hooks.

This is just a glimpse of `Nvar`'s greater aim - centralizing configuration for your environment variables as much as possible. Doing so enables you to onboard developers easily, and makes it easier to hide environment variables from logs and files.

### Passthrough

The final config option, `passthrough`, deserves some extra detail. By default, `Nvar` sets your environment constants to their actual values in development and production environments, and to their names in test environments, in order to prevent your tests from depending on their values.

In production/development, or in test with passthrough active:

```
irb(main):001:0> REQUIRED_ENV_VAR
=> "set"
```

In test:

```
irb(main):001:0> REQUIRED_ENV_VAR
=> "REQUIRED_ENV_VAR"
```

Your tests shouldn't be reliant on your environment, so setting `passthrough` to `true` in `config/environment_variables.yml` isn't recommended. Passthrough is, however, useful for recording VCR cassettes. Set NVAR_PASSTHROUGH to a comma-separated list of environment variable names while running your tests, then unset it and run your tests again to make sure they're not reliant on your environment. For example:

```
NVAR_PASSTHROUGH=GITHUB_APP_PRIVATE_KEY,GITHUB_APP_INSTALLATION_ID bundle exec rspec
```

## Usage

Now that you've been through and configured the environment variables that are necessary for your app, `Nvar` will write your environment variables to top-level constants, cast to any types you've specified, and raise an informative error if any are absent.
### .env files

`Nvar` works well with gems like `dotenv` that source their config from a `.env` file. If an environment variable is unset when the app initializes and isn't present in `.env`, it will be added to that file. If a default value is specified in your `Nvar` config, that will be passed to `.env` too.

When using gems such as `dotenv`, make sure you load those first so that the environment is ready for `Nvar` to check.

### `rake nvar:verify_environment_file`

This Rake task provided by `Nvar` is super helpful for your project's developer experience. Based on what's currently in the environment, it'll show any environment variables that are missing and add declarations for them to `.env`. And if you've set a `default_value` in your config, that'll get written too.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boardfish/nvar. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/boardfish/nvar/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Nvar project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/boardfish/nvar/blob/master/CODE_OF_CONDUCT.md).

## This gem's name

This gem isn't associated with [sneakertack/nvar](https://github.com/sneakertack/nvar).
