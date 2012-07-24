
class Contacts
  class Webde < Base
    PROTOCOL_ERROR      = "Protocol Error"

    def real_connect

      login_url = "https://login.web.de/intern/login/"
      postdata =  "service=freemail&server=https%3A%2F%2Ffreemail.web.de&onerror=https%3A%2F%2Ffreemail.web.de%2Fmsg%2Ftemporaer.htm"
      postdata += "&onfail=http%3A%2F%2Fweb.de%2Ffm%3Fstatus%3Dlogin-failed"
      postdata += "&username=#{CGI.escape(login)}&password=#{CGI.escape(password)}&jsenabled=false"

      data, resp, cookies, forward = post(login_url, postdata)
      @session = forward.scan(/.*session=([0-9A-Z]+)/).flatten.first

      if !forward.index("https://freemail.web.de/intern/jump/?")
        raise AuthenticationError, "Login process failed, incorrect forward URL"
      end
      if @session.empty?
        raise ConnectionError, "Login process failed, no session specified"
      end

      while !@si or @si.empty?
        @si = forward.scan(/si=([-_*0-9A-Za-z.]+)/).flatten.uniq
        @start_page ||= forward
        data, resp, cookies, forward = get(forward, cookies)
        @sid = data.scan(/sid=([0-9A-Fa-f]+)/).flatten.uniq
	#debug "page content: #{data}" 
      	debug "Login loop: session=#{@session}, si=#{@si}, sid=#{@sid}, cookies='#{@cookies}', forward=#{@sart_page}"
      end
      @cookies = cookies

      data, resp, cookies, forward = get("https://navigator.web.de/navigator/show?sid=#{@sid}", @cookies)
      if resp.code_type != Net::HTTPOK
        raise ConnectionError, PROTOCOL_ERROR
      end
      debug "Login ready: session=#{@session}, si=#{@si}, sid=#{@sid}, cookies='#{@cookies}', forward=#{@sart_page}"
    end


    def contacts(options = {})
      return @contacts if @contacts
      #if connected?   # WEB.DE does not send mandatory cookies

        debug "Starting contact export ..."
        uas2server = "navigator.web.de"
        uas2params =  "serviceID=comsaddressbook-live.webde-3c&session=#{@sid}&"
        uas2params += "server=https://#{uas2server}&partnerdata="
	uas2params += CGI.escape("register_url=https://#{uas2server}/intern/logout/register/?sid=#{@sid}&iac_token=&iac_appname=addressbook&navigator_theme=blue&navigator_bg&light")
        uas2url = "https://uas.web.de/intern/jump/?#{uas2params}"
        data, resp, cookies, forward = get(uas2url, "", @start_page)
        debug "Redirect response: #{forward}"
        raise ConnectionError, PROTOCOL_ERROR unless forward.scan(/cab.web.de/)
        raise ConnectionError, PROTOCOL_ERROR if forward.index(/cab.web.de\/error/)

        # Step 2: Get new session ID for addressbook URL
        @session = forward.scan(/.*session=([_\w-]+)/).flatten.first
        debug "URL=#{forward}, Got addressbook session: #{@session}"

        # Step 3: POST addressbook export command with session ID
        posturl = "https://cab.web.de/exportcontacts"
        postdata = "what=PERSON&session=#{@session}&language=de&raw_format=csv_Outlook2003&export=Exportieren"
        data, resp, cookies, forward = post(posturl, postdata, @cookies, forward)

        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end
        debug "Adressbook data: #{data}"
        parse(data, options)

      #end
    end

  private

    # Outlook 2003 format:
    # ["Nachname", "Anrede", "Vorname", "Weitere Vornamen", "Geschlecht", "Geburtstag", "Position", "Abteilung", "Firma", "E-Mail-Adresse", "E-Mail: Angezeigter Name", "E-Mail 2: Adresse", "E-Mail 2: Angezeigter Name", "E-Mail 3: Adresse", "E-Mail 3: Angezeigter Name", "Telefon gesch\344ftlich", "Telefon gesch\344ftlich 2", "Autotelefon", "Telefon privat", "Telefon privat 2", "Mobiltelefon", "Mobiltelefon 2", "Weiteres Telefon", "Fax privat", "Fax gesch\344ftlich", "Weiteres Fax", "Webseite", "Stra\337e gesch\344ftlich", "Ort gesch\344ftlich", "Postleitzahl gesch\344ftlich", "Land gesch\344ftlich", "Stra\337e privat", "Ort privat", "Postleitzahl privat", "Land privat", "Weitere Stra\337e", "Weiterer Ort", "Weitere Postleitzahl", "Weiteres Land", "Notizen"]
    def parse(data, options={})
      @contacts = CSV.parse(data).collect { |input| ["#{input[2]} #{input[0]}", input[9]] }
    end

    TYPES[:webde] = Webde
    NAMES[:webde] = "WEB.de"
    DOMAIN_RES[:webde] = [/[.@]web\.de$/i]
  end

end
