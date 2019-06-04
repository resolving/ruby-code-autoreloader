# frozen_string_literal: true

require 'active_support'
require 'set'
require 'ruby_code_autoreloader/config'
require 'ruby_code_autoreloader/class_loader'

module RubyCodeAutoreloader
  module_function

  def config
    @config ||= configure
  end

  def configure(custom = {})
    @config = ::RubyCodeAutoreloader::Config.new(custom)
  end

  def autoreload_enabled?
    @config.autoreload_enabled
  end

  def start
    init
    load_paths
    set_reloader
  end

  def load_paths
    @config.autoloadable_paths.each do |path|
      if path.end_with?('.rb')
        load_file(path)
      else
        Dir.glob("#{path}/**/*.rb").each do |file|
          load_file(file)
        end
      end
    end

    @config.logger.info "Autoloaded constants #{@autoloaded_classes.inspect}"
  end

  # clear all autoloaded constants before any possible reloading
  def clear
    @autoloaded_classes.to_a.reverse_each do |klass|
      RubyCodeAutoreloader::ClassLoader.remove_constant(klass)
      @autoloaded_classes.delete(klass)
    end

    @existing_modules_before_load.clear
    @autoloaded_files = []
    ActiveSupport::DescendantsTracker.clear
    ActiveSupport::Dependencies.clear
  end

  def reload
    return unless autoreload_enabled?

    @config.logger.info '#RubyCodeAutoreloader: Reloading modules'

    if @config.reload_only_on_change
      @config.file_watchers.map(&:execute_if_updated)
    else
      clear
      load_paths
    end
  end

  def all_autoloaded_classes
    @autoloaded_classes || []
  end

  private

  def self.init
    @existing_modules_before_load = []
    @autoloaded_classes = Set.new
    @autoloaded_files = []
  end

  def self.load_file(file)
    @existing_modules_before_load = ObjectSpace.each_object(Module).to_a
    require_or_load(file)
    RubyCodeAutoreloader::ClassLoader.update_autoloaded_classes(file,
                                                                @autoloaded_classes,
                                                                @existing_modules_before_load)
    @autoloaded_files << file
  end

  def self.set_reloader
    return unless autoreload_enabled?

    callback = lambda do
      clear
      load_paths
    end

    file_watcher = @config.default_file_watcher.new(@autoloaded_files, {}, &callback)
    @config.file_watchers << file_watcher
  end
end
