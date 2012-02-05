module CoTweet
  class Connection
    BASE_URL = URI.parse('https://standard.cotweet.com/')

    def initialize
      cmd.say 'Please log in to your CoTweet account.'
      @email_address = cmd.ask('Email address: ')
      @password = cmd.ask('Password: ') {|q| q.echo = false }
      @cookiejar = CookieJar::Jar.new
    end

    # Command-line interface helpers
    def cmd
      @cmd ||= HighLine.new
    end

    # Returns a deferrable that succeeds with self on successful login.
    def login
      cmd.say 'Logging in...'
      request = EM::HttpRequest.new(BASE_URL.merge('/agent_sessions'))

      request.post(:body => {
        'agent_session[email_address]' => @email_address,
        'agent_session[password]' => @password,
        'agent_session[remember_me]' => 0
      }).transform do |http|

        case http.response_header.status
        when 200
          cmd.say 'Incorrect password'; raise 'login failed'
        when 302
          [http.response_header.cookie].compact.flatten.each do |cookie|
            @cookiejar.set_cookie(request.uri, cookie)
          end
        else
          raise "HTTP #{http.response_header.status}"
        end
        self

      end.errback do
        cmd.say 'Sorry, could not connect to CoTweet.'
      end
    end

    def cookies
      @cookiejar.get_cookies(BASE_URL).map(&:to_s).join('; ')
    end

    def get_json(path, query={})
      EM::HttpRequest.new(BASE_URL.merge(path)).
        get(:query => query, :head => {:cookie => cookies}).
        transform do |http|
          if http.response_header.status == 200
            JSON.parse(http.response)
          else
            cmd.say "Request to #{path} failed with HTTP #{http.response_header.status}"
            raise "HTTP #{http.response_header.status}"
          end
        end
    end

    def self.test!
      EM.run do
        new.login.bind! do |connection|
          connection.get_json '/api/1/channels/sources.json'
        end.bothback do |result|
          puts result.inspect
          EM.stop
        end
      end
    end
  end
end
