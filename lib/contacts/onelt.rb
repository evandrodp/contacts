class Contacts
  class Onelt < Base
    DETECTED_DOMAINS = [ /one\.lt/i ]
    LOGIN_URL = "http://w33.one.lt/logonSubsite.do?subsite=pastas"
    EMAIL_URL = "http://email.one.lt/"
    ADDRESS_BOOK_URL = "http://w33.one.lt/resinRedir.do?pane=email"
    PROTOCOL_ERROR = "One.lt has changed its protocols, please upgrade this library first. If that does not work, report this error at http://rubyforge.org/forum/?group_id=2693"

    attr_accessor :cookies

    def real_connect
      data, resp, self.cookies, forward = get(LOGIN_URL)

      postdata =  "username=%s&password=%s&subsite=pastas" % [
        CGI.escape(username),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward, old_url = post(LOGIN_URL, postdata, self.cookies)

      if data.index("f-login")
        raise AuthenticationError, "Username and password do not match"
      elsif !forward.nil? && forward.match('brutecheck')
        raise AuthenticationError, "Got captcha"
      elsif forward.nil? || !forward.match('tkn')
        raise ConnectionError, PROTOCOL_ERROR
      end
    end

    def contacts
      data, resp, self.cookies, forward = get(ADDRESS_BOOK_URL, self.cookies)

      doc = Nokogiri(data)
      int = nil
      
      (doc/"input[name=int]").each do |input|
        int = input['value']
      end

      postdata = "action=LoginUser&pane=contacts&int=#{int}"
      data, resp, self.cookies, forward = post(EMAIL_URL, postdata, self.cookies)

      contacts = []
      page = 1

      until page.nil? 
        url = "http://email.one.lt/index.html?pane=contacts&page-number=%d" % page

        data, resp, self.cookies, forward = get(url, self.cookies)

        doc = Nokogiri(data)

        (doc/'form[name=contacts_items]//table[2]//tr[class=whiteBg]').each do |tr|
          name = tr.at('td[2]').text.strip
          email = tr.at('td[4]').text.strip

          next if email.empty?

          contacts << [ name, email ]
        end

        page+= 1
        page = nil unless data.match("&page-number=#{page}")
      end

      contacts
    end

    private

    def username
      login.split('@').first
    end

  end

  TYPES[:onelt] = Onelt
  NAMES[:onelt] = "one.lt"
end
