# RubyCodeAutoreloader
A simple way to add code auto-reloading to not Rails app

## Index
- [Usage](#usage)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Naming convention](#naming-convention)    
  - [How to use in an application](#how-to-use-in-an-application)
- [Contributing](CONTRIBUTING.md)
  - [Maintainers](https://github.com/resolving/ruby-code-autoreloader/graphs/contributors)
- [License](#license)


## Usage

### Installation
Add this line to your application's Gemfile:

```ruby
gem 'ruby-code-autoreloader', resolving: 'ruby-code-autoreloader', tag: '0.1.0' # or ref: 'some md5'
```

And then execute:
```bash
$ bundle install
```

### Configuration

To set configuration use `RubyCodeAutoreloader.configure` with a hash of params.
List of possible params:

|  Name  | Default value | Description |
| --- | :---: | --- |
|  default_file_watcher | ActiveSupport::FileUpdateChecker | File watcher class that will be used for checking files  updates |
|  autoreload_enabled | ENV['RACK_ENV'] == 'development' | The code reloading will works only if this param is `true`. Then all libs specified in `autoloadable_paths` will be loaded with `load`  directive, e.g. `load 'lib_path/file.rb'`. If this param  is `false`, then all libs specified in `autoloadable_paths`  will be loaded as usual with `require`. Loading process uses the `ActiveSupport::Dependencies::Loadable.require_or_load` method |
|  autoloadable_paths | [] | This is an `Array` of paths from which will be loaded all  ruby files `'*.rb'`. All files and Classes should be in the compliance with the [`Naming convention`](#naming-convention)  described below. |
|  reload_only_on_change | TRUE | If this is `true`, then Reloader will check files in `autoloadable_paths` with initialized  `file_watcher` and will reload the files if any of them was  updated. If this is `false`, then files will be reloaded on  each `RubyCodeAutoreloader.reload` method call,  e.g. always |
|  logger | Logger.new(STDOUT) | Logger object |                        

Also you can add specific environment variable for changing reloader mode, for 
example `ENV['AUTORELOAD_ENABLED']='true'`, and use it in configure.

Example of initializer with configuration:
```ruby
# config/initializers/ruby_code_autoreloader.rb
require 'ruby_code_autoreloader'

RubyCodeAutoreloader.configure(autoreload_enabled: (ENV['RACK_ENV'] == 'development' &&
                                                    ENV['AUTORELOAD_ENABLED'] == 'true'),
                               reload_only_on_change: false,
                               autoloadable_paths: %w(app/endpoint_flux/middlewares/decorator
                                                      app/endpoint_flux/middlewares/validator
                                                      app/models
                                                      app/endpoint_flux/decorators
                                                      app/endpoint_flux/endpoints
                                                      app/workers).freeze)
```

#### Naming convention

`RubyCodeAutoreloader` will search for all ruby `"*.rb"` files inside directories that described in `autoloadable_paths`.
The pattern for searching files is `Dir.glob("#{path}/**/*.rb")`, e.g. will be loaded all files from subdirectories too.
Each file will be loaded by `load` or `require` directive, depends on `autoreload_enabled` mode. After each file loading,
`RubyCodeAutoreloader` will accumulate loaded Classes/Modules inside module variable `@autoloaded_classes`, that will be
used to remove constant before each `Reloading`. 

And here we have a special `Naming convention`: 
the **_Classes/Modules_** that will be used for `Reloading` (e.g. will be added to `autoloaded_classes`), **should have** 
**the same last module names** as the **`files name`** too. **Otherwise** it will not be included for `Reloading` and 
**will be loaded only once** at the start. 
That's because it's hard to track what modules was loaded from the file as they might have their own `require` libs inside.

For example we have this file `app/endpoint_flux/endpoints/users/create.rb` in specified dir `app/endpoint_flux/endpoints`, 
then Class/Module defined inside should has the name `Create` as **the last module name**, 
e.g. like this `::SomeModule::Create` or `Users::Create` or `EndpointFlux::Users::Create` or just `Create`
 
### How to use in an application

Firstly you need to configure it with initializer, as described in [Configuration](#configuration).
Then you need to call `RubyCodeAutoreloader.start` method after all initializers. 
Depends on the `autoreload_enabled` config param, `RubyCodeAutoreloader` will loads the ruby libs specified in  
`autoloadable_paths` by `load` or `require` directive.

Example of `environment.rb` with initializing the `RubyCodeAutoreloader` by `start` method:
```ruby
# config/environment.rb
ENV['RACK_ENV'] ||= 'development'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

if ENV['RACK_ENV'] == 'development' || ENV['RACK_ENV'] == 'test'
  require 'dotenv'
  Dotenv.load(".env.#{ENV['RACK_ENV']}", '.env')
end

require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'])

$LOAD_PATH.unshift File.expand_path('..', __dir__)
$LOAD_PATH.unshift File.expand_path('../app', __dir__)

Dir.glob('config/initializers/*.rb').each { |file| require file }

require "config/environments/#{ENV['RACK_ENV']}.rb"

RubyCodeAutoreloader.start ### Run it only after all initializers
```

Then you can just put `RubyCodeAutoreloader.reload` to the place where you want to check for updates before starting 
processing the query. In the example below this `call_endpoint_flux` in Sneakers worker will be called on each query 
to the service, and we call `RubyCodeAutoreloader.reload` before another methods. If `autoreload_enabled` is set 
to `false`, then reloading will be skipped.

Example of Sneakers worker with the `RubyCodeAutoreloader.reload` call inside:
```ruby
# app/workers/base_worker.rb
 
module BunnyPublisher
  module EndpointFlux
    class SneakersWorker
      def call_endpoint_flux(message, props)
        action = self.class.endpoint_action || props[:headers]['action']

        RubyCodeAutoreloader.reload # calling it before processing the query

        endpoint = endpoint_for("#{self.class.endpoint_namespace}/#{action}")

        _, response = endpoint.perform(request_object(message))

        response.body
      end
    end
  end
end
```

## [Contributing](CONTRIBUTING.md)

### [Maintainers](https://github.com/resolving/endpoint-flux/graphs/contributors)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
