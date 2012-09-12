class Contacts
  class Seznam < Base
    DETECTED_DOMAINS = [ /seznam\.cz/i, /email\.cz/i, /post\.cz/i, /spoluzaci\.cz/i, /stream\.cz/i, /firmy\.cz/i, ]
    LOGIN_URL = "https://login.szn.cz/loginProcess"
    ADDRESS_BOOK_URL = "http://email.seznam.cz/abookCsvExport?sessionId=&charset=utf-8&eof=windows&export=nameLast&export=nameFirst&export=nick&export=email"

    attr_accessor :cookies

    def real_connect
      postdata =  "disableSSL=0&domain=%s&forceRelogin=0&forceSSL=0&lang=cz&loginType=seznam&returnURL=%s&serviceId=email&username=%s&password=%s" % [
        CGI.escape(domain),
        CGI.escape('http://email.seznam.cz/ticket'),
        CGI.escape(username),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, "")
      
      if !forward.nil? && forward.match("badLogin")
        raise AuthenticationError, "Username and password do not match"
      end

      doc = Nokogiri(data)

      a = doc.at('body>a')
      forward = a['href'].to_s

      data, resp, self.cookies, forward = get(forward, self.cookies)

      doc = Nokogiri(data)

      a = doc.at('body>a')
      forward = a['href'].to_s

      data, resp, self.cookies, forward = get(forward, self.cookies)

      doc = Nokogiri(data)

      a = doc.at('body>a')
      forward = a['href'].to_s

      data, resp, self.cookies, forward = get(forward, self.cookies)      
    end

    def contacts
      @contacts = []
      
      data, resp, self.cookies, forward = get(ADDRESS_BOOK_URL, self.cookies)      

      CSV.parse(data, { :col_sep => ';' }) do |row|
        last_name, first_name, unknown, email = row
        
        name = "#{first_name} #{last_name}".strip
        email.strip!

        @contacts << [name, email] unless email.empty?
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

  TYPES[:seznam] = Seznam
  NAMES[:seznam] = "Seznam"
end