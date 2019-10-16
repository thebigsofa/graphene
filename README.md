# Graphene
Graphene provides a graph based job and task executioner. Jobs comprise of tasks and they
get queued up to process. A visitor checks the graph constantly for job state changes and
processes the rest of the shizzle as it goes.

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
