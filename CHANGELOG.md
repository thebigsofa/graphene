# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.10] - 2019-12-10
### Changed
- Updated pipeline jobs to be able to take multiple parents when building them.

## [0.1.6] - 2019-11-14
### Changed
- Renamed `callback_notifier_delay` configuration option to `callback_delay`
- The `callback_delay` configuration option is now also used instead of ENV.fetch("POLLING_TIMEOUT").to_i in Graphene::Timeoutable class.

### Fixed
- The default value for `sidekiq_callbacks_middleware` configuration option was `30` instead of `Graphene::SidekiqCallbacksMiddleware`. That bug was fixed.
