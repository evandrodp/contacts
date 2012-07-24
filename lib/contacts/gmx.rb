
class Contacts
  class Gmx < Base
    URL                 = "http://www.gmx.net"
    BASE_URL            = "https://service.gmx.net/de/cgi"
    LOGIN_URL           = "#{BASE_URL}/login"
    UAS2_URL            = "https://uas2.uilogin.de/intern/jump"
    ADDRESS_BOOK_URL    = "https://adressbuch.gmx.net/"
    CONTACT_LIST_URL    = "https://adressbuch.gmx.net/exportcontacts"
    PROTOCOL_ERROR      = "Protocol Error"

    def real_connect
      postdata =  "AREA=1&EXT=redirect&EXT2=&dlevel=c"
      postdata += "&id=#{CGI.escape(login)}&p=#{CGI.escape(password)}&jsenabled=false"

      # get uinguserid form value - not necessary?
      #data, resp, cookies, forward = get(URL)
      #uinguserid_el = data.grep ...

      # Set-Cookie: gmxsid_xxx (gmx.net, Session)
      # Set-Cookie: GUD (*.gmx.net, 5 Jahre)
      # Location: g.fcgi/application/navigator?CUSTOMERNO=123456789&t=de1234567890.1234567890.123fadc5a
      # Location: g.fcgi/startpage?CUSTOMERNO=123456789&t=de1234567890.1234567890.123fadc5a
      data, resp, cookies, forward = post(LOGIN_URL, postdata)

      if !forward.index("#{BASE_URL}/g.fcgi")
        raise AuthenticationError, "Login process failed"
      elsif data.index("lose/password")
        raise AuthenticationError, "Username and password do not match"
      elsif cookies == ""
        raise ConnectionError, PROTOCOL_ERROR
      end

      @customerno = forward.scan(/.*CUSTOMERNO=([0-9]+)/).flatten.first
      @t = forward.scan(/.*t=([\w\.]+)/).flatten.first

      data, resp, cookies, forward = get(forward, cookies, LOGIN_URL)

      @cookies = cookies
      @sid = data.scan(/sid=([0-9a-z.]+)/).flatten.uniq
      @start_page = forward  # needed as referrer later on
      debug "Login success. customerno=#{@customerno}, t=#{@t}, cookies='#{@cookies}', sid=#{@sid}"

      if resp.code_type != Net::HTTPOK
        raise ConnectionError, PROTOCOL_ERROR
      end
    end


    def contacts(options = {})
      return @contacts if @contacts
      if connected?

        # Step 1: Register at UIlogin site and get SessionID
        referrer = "#{BASE_URL}/g.fcgi/application/navigator?sid=#{@sid}"
        uas2session = "customerno=#{@customerno}&t=#{@t}&user_agent=#{user_agent}"
        uas2partnerdata = "register_url=#{BASE_URL}/g.fcgi/application/navigator/logout/urlcollector?iac_token=#{@customerid}#{@t}"  # probably not important
        uas2params = "session=#{CGI.escape(uas2session)}&partnerdata=#{CGI.escape(uas2partnerdata)}&serviceID=comsaddressbook-live.gmxde"
        uas2url = "#{UAS2_URL}?#{uas2params}"
        data, resp, cookies, forward = get(uas2url, "", referrer)
        debug "Redirect response: #{forward}"
        raise ConnectionError, PROTOCOL_ERROR unless forward.scan(/adressbuch.gmx.net/)
        raise ConnectionError, PROTOCOL_ERROR if forward.index(/adressbuch.gmx.net\/error/)

        @session = forward.scan(/.*session=([_\w-]+)/).flatten.first
        debug "URL=#{forward}, Got addressbook session: #{@session}"

        postdata = "what=PERSON&session=#{@session}&language=de&raw_format=csv_Outlook2003&export=Exportieren"
        data, resp, cookies, forward = post(CONTACT_LIST_URL, postdata, @cookies, contact_list_url)
        debug "Adressbook data: #{data}"

        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end
        parse(data, options)
      end
    end

  private

    # Outlook 2003 format:
    # ["Nachname", "Anrede", "Vorname", "Weitere Vornamen", "Geschlecht", "Geburtstag", "Position", "Abteilung", "Firma", "E-Mail-Adresse", "E-Mail: Angezeigter Name", "E-Mail 2: Adresse", "E-Mail 2: Angezeigter Name", "E-Mail 3: Adresse", "E-Mail 3: Angezeigter Name", "Telefon gesch\344ftlich", "Telefon gesch\344ftlich 2", "Autotelefon", "Telefon privat", "Telefon privat 2", "Mobiltelefon", "Mobiltelefon 2", "Weiteres Telefon", "Fax privat", "Fax gesch\344ftlich", "Weiteres Fax", "Webseite", "Stra\337e gesch\344ftlich", "Ort gesch\344ftlich", "Postleitzahl gesch\344ftlich", "Land gesch\344ftlich", "Stra\337e privat", "Ort privat", "Postleitzahl privat", "Land privat", "Weitere Stra\337e", "Weiterer Ort", "Weitere Postleitzahl", "Weiteres Land", "Notizen"]
    def parse(data, options={})
      @contacts = CSV.parse(data).collect { |input| ["#{input[2]} #{input[0]}", input[9]] }
    end

    TYPES[:gmx] = Gmx
    DOMAIN_RES[:gmx] = [/[.@]gmx\./i]
  end

end
