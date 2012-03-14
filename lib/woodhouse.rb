module Woodhouse
  WoodhouseError = Class.new(StandardError)
  WorkerNotFoundError = Class.new(WoodhouseError)
  ConnectionError = Class.new(WoodhouseError)
  ConfigurationError = Class.new(WoodhouseError)

  module Util
    
    private

    def expect_arg(name, klass, value)
      unless value.kind_of?(klass)
        raise ArgumentError, "expected #{name} to be a #{klass.name}, got #{value.class}"
      end
    end

    def expect_arg_or_nil(name, klass, value)
      expect_arg(name, klass, value) unless value.nil?
    end

  end

  # TODO: hate keeping global state in this model. I need to push
  # some of this down into NodeConfiguration or something like it.
  class << self

    def global_configuration
      @global_configuration ||= Woodhouse::NodeConfiguration.default
    end

    def configure(&blk)
      @global_configuration = Woodhouse::NodeConfiguration.new(&blk)
    end
  
    def global_layout
      @global_layout ||= Woodhouse::Layout.default
    end

    def layout(&blk)
      @global_layout = Woodhouse::Layout.new.tap(&blk)
    end

    def dispatch(*a)
      global_configuration.make_dispatcher.dispatch(*a)
    end

  end

end

require 'fiber18'
require 'celluloid'
require 'woodhouse/layout'
require 'woodhouse/scheduler'
require 'woodhouse/server'
require 'woodhouse/queue_criteria'
require 'woodhouse/node_configuration'
require 'woodhouse/registry'
require 'woodhouse/mixin_registry'
require 'woodhouse/worker'
require 'woodhouse/dispatcher'
require 'woodhouse/local_dispatcher'
require 'woodhouse/job_execution'
require 'woodhouse/bunny_dispatcher'
require 'woodhouse/runners'