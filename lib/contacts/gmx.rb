# -*- encoding : utf-8 -*-

class Contacts
  class Gmx < Base
    DETECTED_DOMAINS = [ /gmx.de/i, /gmx.at/i, /gmx.ch/i, /gmx.net/i ]
    LOGIN_URL = "https://service.gmx.net/de/cgi/login"
    ADDRESS_BOOK_URL = "https://service.gmx.net/de/cgi/g.fcgi/addressbook/cab?cc=subnavi_adressbuch&sid="
    EXPORT_URL = "https://adressbuch.gmx.net/exportcontacts"

    attr_accessor :cookies, :sid

    def real_connect

      postdata =  "AREA=1&EXT=redirect&EXT2=&dlevel=c&id=%s&p=%s&uinguserid=__uuid__" % [
        CGI.escape(login),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, "")

      if data.index("lose/password")
        raise AuthenticationError, "Username and password do not match"
      elsif !forward.nil? && forward.index("login-failed")
        raise AuthenticationError, "Username and password do not match"
      elsif cookies == "" or data == ""
        raise ConnectionError, PROTOCOL_ERROR
      end

      data, resp, self.cookies, forward = get(forward, self.cookies)
      
      self.sid = data.match(/sid=([a-z0-9\.]+)/)[1]      
    end

    def contacts
      data, resp, cookies, forward = get(ADDRESS_BOOK_URL + self.sid, self.cookies)
      data, resp, cookies, forward = get(forward, self.cookies)

      session = forward.match(/session=([^&]+)/)[1]      

      postdata = "language=eng&raw_format=csv_Outlook2003&what=PERSON&session=" + session

      data, resp, cookies, forward = post(EXPORT_URL, postdata, self.cookies)
  
      @contacts = []

      CSV.parse(data) do |row|
        @contacts << ["#{row[2]} #{row[0]}", row[9]] unless header_row?(row)
      end

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

  TYPES[:gmx] = Gmx
  NAMES[:gmx] = "GMX"
end
