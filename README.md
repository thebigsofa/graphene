# Graphene
Graphene provides a graph based job and task executioner. Jobs comprise of tasks and they
get queued up to process. A visitor checks the graph constantly for job state changes and
processes the rest of the shizzle as it goes.

![](https://pbs.twimg.com/profile_images/620325842703511552/r4KM_c-M_400x400.jpg)

## Instalation
Add the following to your gemfile:
```ruby
gem "graphene", github: "https://github.com/thebigsofa/graphene"
```

Run the bundle command:
```bash
bundle install
```

Install default initializer configuration:
```bash
rake graphene:install:config
```

Run the migrations (this will only run graphene migrations)
```bash
rake db:migrate SCOPE=graphene
```

or run all the app's migrations:
```bash
rake db:migrate
```

## Configuration
Graphene provides a mechanism configure certain aspects of it. Create an initializer called `graphene.rb` in your initializers folder with the following:
```ruby
Graphene.configure do |config|
end
```
### Authentication
By default, there is no authentication provided however you can plug in your own authentication middleware (rack middleware).
```ruby
Graphene.configure do |config|
  config.auth_middleware = MyAuthClass
end
```
### Sidekiq Tracker
The sidekiq tracker is responsible for sending sidekiq metrics to AWS for auto-scaling. By default this is nil but if you wish to override it, use the folling configuration option:
```ruby
Graphene.configure do |config|
  config.sidekiq_tracker = MySidekiqTrackerClass
end
```

### Contributions / Upgrading
- When a new PR is created the `VERSION` should be updated, otherwise the gem will be overwitten in Nexus, which will render `bundle update` unable to do its job.
- When a PR is created all the tests are run. The PR can be merged when all the tests passed.
- After the PR is merged, CircleCI runs all the tests again, as well as the `build` workflow. The `build` creates a gem bundle and pushes the gem into the nexus repository. After that `bundle update graphene` command can be run in the application using the gem, to upgrade to the newest version.
