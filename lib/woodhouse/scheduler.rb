class Woodhouse::Scheduler
  include Woodhouse::Util
  include Celluloid

  class SpunDown < StandardError

  end

  class WorkerSet
    include Woodhouse::Util
    include Celluloid

    attr_reader :worker

    def initialize(scheduler, worker, config)
      expect_arg_or_nil :worker, Woodhouse::Layout::Worker, worker
      @scheduler = scheduler
      @worker_def = worker
      @config = config
      @threads = []
      spin_up
    end

    def spin_down
      @spinning_down = true
      @threads.each do |thread|
        thread.spin_down
      end
      @scheduler.remove_worker(@worker_def)
      signal :spun_down
    end

    def wait_until_done
      wait :spun_down
    end

    private

    def spin_up
      @worker_def.threads.times do
        @threads << @config.runner_type.new_link(@worker_def, @config)
      end
    end

  end

  def initialize(config)
    @config = config
    @worker_sets = {}
  end

  def start_worker(worker)
    @worker_sets[worker] = WorkerSet.new_link(Celluloid.current_actor, worker, @config) unless @worker_sets.has_key?(worker)
  end

  def stop_worker(worker, wait = false)
    if set = @worker_sets[worker]
      set.spin_down!
      set.wait_until_done if wait
    end
  end
  
  def running_worker?(worker)
    @worker_sets.has_key?(worker)
  end

  def spin_down
    @spinning_down = true
    @worker_sets.each do |worker, set|
      set.spin_down!
    end
    @worker_sets.keys.each do |worker|
      set = @worker_sets[worker]
      set.wait_until_done
    end
  end

  protected

  def remove_worker(worker)
    @worker_sets.delete(worker)
  end
end