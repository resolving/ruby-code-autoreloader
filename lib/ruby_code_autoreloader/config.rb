# frozen_string_literal: true

require 'active_support/file_update_checker'
require 'active_support/executor'
require 'active_support/reloader'
require 'logger'

module RubyCodeAutoreloader
  class Config
    attr_reader   :default_file_watcher, :autoloadable_paths, :autoreload_enabled,
                  :reloader, :executor, :environment, :logger, :reload_only_on_change

    attr_accessor :file_watchers

    def initialize(params = {})
      @default_file_watcher  = params.fetch(:default_file_watcher, ActiveSupport::FileUpdateChecker)
      @autoloadable_paths    = params.fetch(:autoloadable_paths, [])
      ## This will be used in later versions of gem
      @executor              = params.fetch(:executor, Class.new(ActiveSupport::Executor))
      @reloader              = params.fetch(:reloader, Class.new(ActiveSupport::Reloader))
      ##
      @autoreload_enabled    = params.fetch(:autoreload_enabled, ENV['RACK_ENV'] == 'development')
      @reload_only_on_change = params.fetch(:reload_only_on_change, true)
      @logger                = params.fetch(:logger, Logger.new(STDOUT))

      @file_watchers         = []
      @environment           = ENV['RACK_ENV']
      @logger.level ||= Logger::INFO
      @reloader.executor = @executor

      ActiveSupport::Dependencies.mechanism = @autoreload_enabled ? :load : :require
    end
  end
end
