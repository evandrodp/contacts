class Contacts
  class WebDe < Base
    DETECTED_DOMAINS = [ /web\.de/i ]
    LOGIN_URL = "https://uas2.uilogin.de/centrallogin-3.1/login"
    ADDRESS_BOOK_URL = "https://mm.web.de/contacts"


    attr_accessor :cookies

    def real_connect
      postdata =  "serviceID=%s&username=%s&password=%s" % [
        CGI.escape('mobile.web.mail.webde.live'),
        CGI.escape(login),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, "")

      if !forward.index("/success")
        raise AuthenticationError, "Username and password do not match"
      end

      data, resp, self.cookies, forward = get(forward, self.cookies)

    end

    def contacts
      url = ADDRESS_BOOK_URL
      @contacts = []

      begin
        data, resp, self.cookies, forward = get(url, self.cookies)
        data, resp, cookies, forward = get(forward, self.cookies)

        doc = Nokogiri(data)

        (doc/'ul[id=addressLines]/li').each do |li|
          links = (li/'a')
          
          name = links[0].text.strip
          name = name.split(', ').reverse.join(' ')

          next if links[1].nil?
          
          match = links[1]['href'].match('to=([^&]+)')
          
          next if !match

          email = match[1].strip
          
          @contacts << [ name, email ]
        end
        
        a_next = doc.at('a[id=go-next]')
        
        unless a_next.nil?
          url = ADDRESS_BOOK_URL + '?' + a_next[:href].split('?')[1]
        else
          url = nil
        end

      end while !url.nil?

      @contacts
    end

    def skip_gzip?
      false
    end

    private

    def header_row?(row)
      row[0] == 'Last Name'
    end
  end

  TYPES[:web_de] = WebDe
  NAMES[:web_de] = "WEB.de"
end