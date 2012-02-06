module CoTweet
  class Export

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def export_timeline(timeline_name)
      file = File.open("#{timeline_name}.json", 'w')
      file.puts '{"items": ['
      first_message = true

      connection.each_message(timeline_name) do |msg|
        file.puts ',' unless first_message
        file.write JSON.pretty_generate(msg)
        first_message = false
      end.bothback do
        file.puts ']}'
        file.close
      end
    end

    def run
      JoinCarefully.setup! *%w(messages sent closed).map(&method(:export_timeline))
    end

    def self.run!
      EM.run do
        Connection.new.login.bind! do |connection|
          Export.new(connection).run
        end.errback do |error|
          puts "Error: #{error.inspect}"
          puts error.backtrace.map{|line| "    #{line}" }.join("\n") if error.respond_to? :backtrace
        end.bothback do
          EM.stop
        end
      end
    end

    # If any of the joined deferrables fails, fails immediately with that failure's error.
    # Otherwise waits for all deferrables to succeed, and succeeds with an array of success results.
    class JoinCarefully < DeferrableGratification::Combinators::Join
      private
      def done?
        failures.length > 0 || all_completed?
      end

      def finish
        if failures.empty?
          succeed(successes)
        else
          fail(failures.first)
        end
      end
    end
  end
end
