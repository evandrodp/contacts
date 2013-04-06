# -*- encoding : utf-8 -*-

class Contacts
  class Gmx < Base
    DETECTED_DOMAINS = [ /gmx.de/i, /gmx.at/i, /gmx.ch/i, /gmx.net/i ]
    LOGIN_URL = "https://service.gmx.net/de/cgi/login"
    EXPORT_URL = "https://cab.gmx.net/exportcontacts"

    attr_accessor :cookies, :sid, :iac_token, :aburl, :lasturl

    def real_connect

      postdata =  "AREA=1&EXT=redirect&EXT2=&dlevel=c&tld=de&successURL=navigator.gmx.net&id=%s&p=%s&jsenabled=true&uinguserid=" % [
        CGI.escape(login),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, "")

      if data.index("lose/password")
        raise AuthenticationError, "Username and password do not match"
      elsif !forward.nil? && forward.index("login-failed")
        raise AuthenticationError, "Username and password do not match"
      elsif !cookies.match(/gmxsid_de.*GUD=/) or data == "" or data.index("error_404")
        raise ConnectionError, "GMX Login: Protocol or missing cookies error"
      end

      until forward.nil?
        self.lasturl = forward
        data, resp, self.cookies, forward = get(forward, self.cookies)
      end
      if remindlogoutlink = data.match(/https:[^']+remindlogout[^']+/)
        data, resp, self.cookies, forward = get(remindlogoutlink[0], self.cookies)
        if navlink = data.match(/'(https:..navigator.gmx.net.[^']+)'/)
          data, resp, self.cookies, forward = get(navlink[1], self.cookies)
          self.lasturl = navlink[1]
        end
      end
      # might be required -> JS code hints that if missing, you get redirected to "unsupportedbrowser.jsp"
      self.cookies << "; vpheight=1074; vpwidth=996; sheight=1200; swidth=1920"
      self.cookies = self.cookies.gsub(/Expires=[^\;]+; /, '')    # not sure if this is necessary
      #debug data

      # extract tokens for addressbook URL.
      self.sid = data.match(/sid=([a-z0-9\.]+)/)[1]      
      self.iac_token = data.match(/"context_token":"([^"]*)"/)[1]
      # extract addressbook URL from JSON garbage in page javascript.
      if aburl = data.match(/"([^"]+serviceID=comsaddressbook-homerun.gmxde[^"]+)"/)
        self.aburl = aburl[1].gsub(/\\/, '')
      end

      # are these really necessary?
      addparam = "&navigator_theme=intenseblue&navigator_bg=intenseblue#fejspghw"
      data, resp, cookies, forward = get("https://trackbar.navigator.gmx.net/?sid=#{self.sid}#{addparam}", self.cookies, self.lasturl)
      data, resp, cookies, forward = get("https://home.navigator.gmx.net/home/show?sid=#{self.sid}#{addparam}", self.cookies, self.lasturl)
      data, resp, cookies, forward = get("https://home.navigator.gmx.net/home/getmodule/XXX?sid=#{self.sid}#{addparam}", self.cookies, self.lasturl)
      data, resp, cookies, forward = get("https://home.navigator.gmx.net/servicemediacenter/data?sid=#{self.sid}&_=#{Time.now.to_i}", self.cookies, self.lasturl)
      data, resp, cookies, forward = get("https://home.navigator.gmx.net/servicefreereader/data?sid=#{self.sid}&_=#{Time.now.to_i}", self.cookies, self.lasturl)
      data, resp, cookies, forward = get("https://home.navigator.gmx.net/servicewetter/json?sid=#{self.sid}&_=#{Time.now.to_i}", self.cookies, self.lasturl)
      data, resp, cookies, forward = get("https://home.navigator.gmx.net/servicetrinity/data?sid=#{self.sid}&_=#{Time.now.to_i}", self.cookies, self.lasturl)

      #debug "lasturl = #{self.lasturl}"
      #debug "sid = #{self.sid}, token = #{self.iac_token}, aburl=#{self.aburl}"
      debug "cookies = #{self.cookies}"
    end


    def contacts
      # New domain (uas2.uilogon.de) => no cookies transfer
      data, resp, self.cookies, forward = get(self.aburl + "#spfakhwl", "", self.lasturl)
      #debug data
      until forward.nil?
        debug "Got fwd: #{forward}, data: #{data}"
        if forward =~ /error/; raise ConnectionError, "Addressbook URL not accessible"; end
        session = forward.match(/session=([^&]+)/)[1]
        data, resp, self.cookies, forward = get(forward, self.cookies)
      end

      postdata = "language=eng&raw_format=csv_Outlook2003&what=PERSON&session=" + session

      data, resp, cookies, forward = post(EXPORT_URL, postdata, cookies)
      debug data.split(/\n/)[0]
  
      @contacts = []

      CSV.parse(data) do |row|
        @contacts << ["#{recode(row[2])} #{recode(row[0])}", recode(row[9])] unless header_row?(row)
      end

      @contacts
    end


    def skip_gzip?
      false
    end

    private

    def recode(str)
      str.force_encoding("ISO8859-1").encode("UTF-8")
    end

    def header_row?(row)
      row[0] == 'Last Name'
    end
  end

  TYPES[:gmx] = Gmx
  NAMES[:gmx] = "GMX"
end
