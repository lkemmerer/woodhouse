#
# A Runner implementation that uses hot_bunnies, a JRuby AMQP client using the
# Java client for RabbitMQ. This class can be loaded if hot_bunnies is not
# available, but it will fail upon initialization. If you want to use this
# runner (it's currently the only one that works very well), make sure to
# add
#
#   gem 'hot_bunnies'
#
# to your Gemfile. This runner will automatically be used in JRuby.
#
class Woodhouse::Runners::HotBunniesRunner < Woodhouse::Runner
  begin
    require 'hot_bunnies'
  rescue LoadError => err
    define_method(:initialize) {|*args|
      raise err
    }
  end

  def subscribe
    Woodhouse::HotBunniesConnection.new(@config.server_info).connect do |cx|
      cx.open_channel do |channel|
        channel.enable_prefetch
        channel.worker_queue(@worker).subscribe do |message|
          handle_job message, message.woodhouse_job
        end
      end
      wait :spin_down
    end
  end

  def spin_down
    signal :spin_down
  end

  def bail_out(err)
    raise Woodhouse::BailOut, "#{err.class}: #{err.message}"
  end

  private

  def handle_job(message, job)
    begin
      if can_service_job?(job)
        if service_job(job)
          message.ack
        else
          message.reject
        end
      else
        @config.logger.error("Cannot service job #{job.describe} in queue for #{@worker.describe}")
        message.reject
      end
    rescue => err
      begin
        @config.logger.error("Error bubbled up out of worker. This shouldn't happen. #{err.message}")
        err.backtrace.each do |btr|
          @config.logger.error("  #{btr}")
        end
        message.reject
      ensure
        bail_out(err)
      end
    end
  end

end
