require 'bunny'

class Woodhouse::Runners::BunnyRunner < Woodhouse::Runner
  include Celluloid

  def subscribe
    bunny = Bunny.new(@config.server_info)
    bunny.start
    bunny.qos(:prefetch_count => 1)
    queue = bunny.queue(@worker.queue_name)
    exchange = bunny.exchange(@worker.exchange_name, :type => :headers)
    queue.bind(exchange, :arguments => @worker.criteria.amqp_headers)
    while not @stopped
      message = queue.pop(:ack => true)
      if message[:header].nil?
        sleep 0.5
      else
        job = make_job(message)
        if can_service_job?(job)
          queue.ack message
          service_job(job)
        else
          queue.reject message
        end
        sleep 0.1
      end
    end
    bunny.stop
    signal :spun_down
  end

  def spin_down
    @stopped = true
    wait :spun_down
  end

  def make_job(message)
    Woodhouse::Job.new(@worker.worker_class_name, @worker.job_method) do |job|
      args = message[:header].properties.merge(:payload => message[:payload])
      args.merge!(args.delete(:headers) || {})
      job.arguments = args
    end
  end

end
