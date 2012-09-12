class Contacts
  class InboxLt < Base
    DETECTED_DOMAINS = [ /inbox\.lt/i ]
    URL = "http://www.inbox.lt/?language=lt"
    LOGIN_URL = "https://login.inbox.lt/redirect.php"
    ADDRESS_BOOK_URL = "http://mail.inbox.lt/horde/turba/?char=&sort=name&page=%d"
    PROTOCOL_ERROR = "inbox.lt has changed its protocols"

    attr_accessor :cookies

    def real_connect
      data, resp, self.cookies, forward = get(URL, "")
      
      doc = Nokogiri(data)

      salt_el = doc.at('input[name=salt]')

      if salt_el.nil?
        raise ConnectionError, PROTOCOL_ERROR
      end

      salt = salt_el['value']

      postdata =  "language=lt&passhash=&salt=%s&redirect_url=%s&redirect_vars=imapuser,usessl&imapuser=%s&pass=%s&usessl=1" % [
        CGI.escape(salt),
        CGI.escape('http://www.inbox.lt/index.php?actionID=imp_login'),
        CGI.escape(username),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, "")

      if forward.nil? || !forward.match("logged_in=1")
        raise AuthenticationError, "Username and password do not match"
      end

      until forward.nil?
        data, resp, self.cookies, forward = get(forward, self.cookies)
      end
    end

    def contacts
      @contacts = []
      page = 0

      until page.nil?
        url = ADDRESS_BOOK_URL % page
        
        data, resp, self.cookies, forward = get(url, self.cookies)      

        doc = Nokogiri(data)

        (doc/"form#contactsForm table table[1] tr").each do |tr|
          name_td = tr.at('td[2]')
          email_td = tr.at('td[3]')

          next if name_td.nil? || email_td.nil?

          name = name_td.text.strip
          email = email_td.text.strip

          next unless email.match('@')

          @contacts << [ name, email ]          
        end

        page+= 1
        page = nil unless data.match("&page=#{page}")
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

  TYPES[:inbox_lt] = InboxLt
  NAMES[:inbox_lt] = "inbox.lt"
end