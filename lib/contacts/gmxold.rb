# -*- encoding : utf-8 -*-

# GMX extraction without javascript.

class Contacts
  class GmxOld < Base
    DETECTED_DOMAINS = [ /gmx.de/i, /gmx.at/i, /gmx.ch/i, /gmx.net/i ]
    EXPORT_URL = "https://cab.gmx.net/exportcontacts"

    attr_accessor :cookies, :sid, :iac_token, :aburl, :lasturl

    def real_connect
      data, resp, self.cookies, forward = get("https://www.gmx.net")

      postdata = "AREA=1&EXT=redirect&EXT2=&uinguserid=__uuid__&dlevel=c&tld=de&successURL=navigator.gmx.net&id=%s&p=%s" % [ CGI.escape(login), CGI.escape(password) ]
      data, resp, self.cookies, forward = post("https://service.gmx.net/de/cgi/login", postdata, "", "")
      # Set-Cookie: GUD (.gmx.net)
      # Set-Cookie: gmxsid_de15938... (gmx.net)
      # fwd: g.fcgi/application/navigator?CUSTOMERNO=...&t=de....&lALIAS=&lDOMAIN=&lLASTLOGIN=2013%2D04%2D07+15%3A37%3A34&tld=de
      # fwd: https://navigator.gmx.net/intern/login/?CUSTOMERNO=....&t=de.....
      # Set-Cookie: fbb.....=.... (navigator.gmx.net)
      referer = "https://service.gmx.net/de/cgi/login"
      until forward.nil?
        oldfwd = forward
        data, resp, self.cookies, forward = get(forward, self.cookies, referer)
        referer = oldfwd
      end

      # confirm GMX's nojs-warning
      last_uilogin_url = nil
      # https://uas2.uilogin.de/intern/jump?serviceID=mobile.web.mail.gmxnet.live&session=....&server=https%3A%2F%2Fnavigator.gmx.net&partnerdata=
      # -> https://mm.gmx.net/success?sessionid=....&partnerdata=
      # -> https://mm.gmx.net/;?jsessionid=......
      # Set-Cookie: JSESSIONID=......
      if uiloginurl = data.match(/"(https:..uas2.uilogin.de.intern.jump[^"]+)"/)
        data, resp, uicookies, forward = get(uiloginurl[1], "", referer)
        referer = uiloginurl[1]
        until forward.nil?
          oldfwd = forward
          data, resp, uicookies, forward = get(forward, self.cookies, referer)
          referer = oldfwd
        end
      end
      debug "data = #{data}"

    end


    def contacts

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

  TYPES[:gmxold] = GmxOld
  NAMES[:gmxold] = "GMX"
end
