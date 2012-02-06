module CoTweet
  class DownloadQueue
    MAX_CONCURRENCY = 10

    def initialize(&block)
      @operation = block
      @items_seen = Set.new
      @active = {}
      @queued = []
    end

    def <<(item)
      return if @items_seen.include? item
      @items_seen << item

      if has_capacity?
        start(item)
      else
        @queued << item
      end
    end

    def finish
      return DG.success if idle?
      @finishing ||= DG.blank
    end

    private

    def idle?
      @active.empty?
    end

    def has_capacity?
      @active.size < MAX_CONCURRENCY
    end

    def start(item)
      @active[item] = @operation.call(item).bothback do
        @active.delete item
        start(@queued.shift) if has_capacity? && !@queued.empty?
        @finishing.succeed if @finishing && idle?
      end
    end
  end
end
