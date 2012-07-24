class Contacts
  class TmobileDe < Base
    URL = "https://email.t-online.de/V4-0-4-0/srv-bin/aaa?method=deliverLoginBox"
    ADDRESS_BOOK_URL = "https://email.t-online.de/V4-0-4-0/srv-bin/addressbook?method=exportAdressbook&p%5Bformat%5D=CSV&p%5Bliid%5D="
    PROTOCOL_ERROR = "t-mobile.de has changed its protocols"

    attr_accessor :cookies, :tid

    def real_connect
      data, resp, self.cookies, forward = get(URL, "")
      debug data
      doc = Hpricot(data)
      meta = doc.at('meta[http-equiv=refresh]')

      if meta.nil?
        raise AuthenticationError, PROTOCOL_ERROR
      end

      forward = meta['content'].split('URL=').last
      
      data, resp, self.cookies, forward = get(forward, self.cookies)

      doc = Hpricot(data)

      self.tid = doc.at('input[name=tid]')['value']
      url = doc.at('form[name=login]')['action']

      postdata =  "appid=0158&lang=de&login=Login&pwd=%s&skinid=30&tid=%s&usr=%s" % [
        CGI.escape(password),
        CGI.escape(self.tid),
        CGI.escape(username)
      ]

      data, resp, self.cookies, forward = post(url, postdata, self.cookies)
      
      if forward.nil? || !forward.match("loadUser")
        raise AuthenticationError, "Username and password do not match"
      end

      data, resp, self.cookies, forward = get(forward, self.cookies)
    end

    def contacts
      @contacts = []
      
      data, resp, self.cookies, forward = get(ADDRESS_BOOK_URL, self.cookies)      

      CSV.parse(data) do |row|
        other, first_name, last_name, email = row
        
        name = "#{first_name} #{last_name}".strip
        email.strip!

        next unless email.include?('@')

        @contacts << [name, email]
      end
   
      @contacts
    end

    def skip_gzip?
      false
    end

    private

    def username
      @login.split('@').first
    end

    def domain
      @login.split('@').last
    end
  end

  TYPES[:tmobile_de] = TmobileDe
  DOMAIN_RES[:tmobile_de] = [/[.@]t-mobile\./i]
end