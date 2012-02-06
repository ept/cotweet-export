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
            cmd.say "success: #{http.encode_query(http.req.uri, query)}"
            JSON.parse(http.response)
          else
            cmd.say "Request to #{path} failed with HTTP #{http.response_header.status}"
            raise "HTTP #{http.response_header.status}"
          end
        end
    end

    # Values for timeline_name:
    #  * 'messages' is the inbox (non-archived messages). It has subcategories:
    #    'dms' is received DMs, 'replies' is received @replies, 'mentions' is received @mentions
    #  * 'twitter_friends_timeline' is friends' updates
    #  * 'sent' is sent messages
    #  * 'closed' is the archive
    def each_message(timeline_name, &block)
      finished = false
      waterline = nil
      DG::loop_until(proc { finished }) do
        query = {:limit => 40}
        query[:max] = waterline if waterline

        get_json("/api/1/timeline/#{timeline_name}.json", query).safe_callback do |json|
          finished = json['items'].nil? || json['items'].empty?
          unless finished
            waterline = json['items'].last['id']
            json['items'].each(&block)
          end
        end
      end
    end
  end
end
