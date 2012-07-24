require "cgi"
require "net/http"
require "net/https"
require "uri"
require "zlib"
require "stringio"
require "thread"
require "erb"

class Contacts
  TYPES = {}
  DOMAIN_RES = {}      # Domains for type autodetection
  VERSION = "1.2.4"
  
  class Base
    def initialize(login, password, options={})
      @login = login
      @password = password
      @captcha_token = options[:captcha_token]
      @captcha_response = options[:captcha_response]
      @connections = {}
      connect
    end
    
    def connect
      raise AuthenticationError, "Login and password must not be nil, login: #{@login.inspect}, password: #{@password.inspect}" if @login.nil? || @login.empty? || @password.nil? || @password.empty?
      real_connect
    end
    
    def connected?
      @cookies && !@cookies.empty?
    end

    def contacts(options = {})
      return @contacts if @contacts
      if connected?
        url = URI.parse(contact_list_url)
        http = open_http(url)
        resp, data = http.get("#{url.path}?#{url.query}",
          "Cookie" => @cookies
        )
        
        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end
        
        parse(data, options)
      end
    end
    
    def login
      @attempt ||= 0
      @attempt += 1
            
      if @attempt == 1
        @login
      else
        if @login.include?("@#{domain}")
          @login.sub("@#{domain}","")
        else
          "#{@login}@#{domain}"
        end
      end
    end
    
    def password
      @password
    end

    def skip_gzip?
      false
    end

    def user_agent
      "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1) Gecko/20061010 Firefox/2.0"
    end

  private
  
    def domain
      @d ||= URI.parse(self.class.const_get(:URL)).host.sub(/^www\./,'')
    end

    def contact_list_url
      self.class.const_get(:CONTACT_LIST_URL)
    end

    def address_book_url
      self.class.const_get(:ADDRESS_BOOK_URL)
    end

    def open_http(url)
      c = @connections[Thread.current.object_id] ||= {}
      http = c["#{url.host}:#{url.port}"]
      unless http
        http = Net::HTTP.new(url.host, url.port)
        if url.port == 443
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        c["#{url.host}:#{url.port}"] = http
      end
      http.start unless http.started?
      http
    end
    
    def cookie_hash_from_string(cookie_string)
      cookie_string.split(";").map{|i|i.split("=", 2).map{|j|j.strip}}.inject({}){|h,i|h[i[0]]=i[1];h}
    end
    
    def parse_cookies(data, existing="")
      return existing if data.nil?

      cookies = cookie_hash_from_string(existing)
      
      data.gsub!(/ ?[\w]+=EXPIRED;/,'')
      data.gsub!(/ ?expires=(.*?, .*?)[;,$]/i, ';')
      data.gsub!(/ ?(domain|path)=[\S]*?[;,$]/i,';')
      data.gsub!(/[,;]?\s*(secure|httponly)/i,'')
      data.gsub!(/(;\s*){2,}/,', ')
      data.gsub!(/(,\s*){2,}/,', ')
      data.sub!(/^,\s*/,'')
      data.sub!(/\s*,$/,'')
      
      data.split(", ").map{|t|t.to_s.split(";").first}.each do |data|
        k, v = data.split("=", 2).map{|j|j.strip}
        if cookies[k] && v.empty?
          cookies.delete(k)
        elsif v && !v.empty?
          cookies[k] = v
        end
      end
      
      cookies.map{|k,v| "#{k}=#{v}"}.join("; ")
    end
    
    def remove_cookie(cookie, cookies)
      parse_cookies("#{cookie}=", cookies)
    end
    
    def post(url, postdata, cookies="", referer="")
      debug "posting url='#{url}' postdata='#{postdata}'"
      url = URI.parse(url)
      http = open_http(url)
      http_header = { "User-Agent" => self.user_agent,
        "Accept-Encoding" => "gzip",
        "Cookie" => cookies,
        "Referer" => referer,
        "Content-Type" => 'application/x-www-form-urlencoded'
      }
      http_header.reject!{|k, v| k == 'Accept-Encoding'} if skip_gzip?
      resp, data = http.post(url.path, postdata, http_header)
      data = uncompress(resp, data)
      cookies = parse_cookies(resp.response['set-cookie'], cookies)
      forward = resp.response['Location']
      forward ||= (data =~ /<meta.*?url='([^']+)'/ ? CGI.unescapeHTML($1) : nil)
      if forward and URI.parse(forward).host.nil?
        forward = url.scheme.to_s + "://" + url.host.to_s + forward
      end
      #debug "... received #{resp.inspect}, Location=#{forward}"
      return data, resp, cookies, forward
    end
    
    def get(url, cookies="", referer="")
      debug "getting url='#{url}'"
      url = URI.parse(URI.escape(url))
      http = open_http(url)
      resp, data = http.get("#{url.path}?#{url.query}",
        "User-Agent" => self.user_agent,
        "Accept-Encoding" => "gzip",
        "Cookie" => cookies,
        "Referer" => referer
      )
      data = uncompress(resp, data)
      cookies = parse_cookies(resp.response['set-cookie'], cookies)
      forward = resp.response['Location']
      if forward and URI.parse(URI.escape(forward)).host.nil?
        forward = url.scheme.to_s + "://" + url.host.to_s + forward
      end
      #debug "... received #{resp.inspect}, Location=#{forward}"
      return data, resp, cookies, forward
    end
    
    def uncompress(resp, data)
      case resp.response['content-encoding']
      when 'gzip'
        gz = Zlib::GzipReader.new(StringIO.new(data))
        data = gz.read
        gz.close
        resp.response['content-encoding'] = nil
      # FIXME: Not sure what Hotmail was feeding me with their 'deflate',
      #        but the headers definitely were not right
      when 'deflate'
        data = Zlib::Inflate.inflate(data)
        resp.response['content-encoding'] = nil
      end

      data
    end

    def debug(str)
      puts "#{caller.first.gsub(/.*\//, '')}: #{str}" if ENV['DEBUG']
    end

  end

  def self.debug(str)
    puts "#{caller.first.gsub(/.*\//, '')}: #{str}" if ENV['DEBUG']
  end

  class ContactsError < StandardError
  end
  
  class AuthenticationError < ContactsError
  end

  class ConnectionError < ContactsError
  end
  
  class TypeNotFound < ContactsError
  end
  
  def self.new(type, login, password, options={})
    if type.to_s == 'auto' and !DOMAIN_RES.empty?
      DOMAIN_RES.each do | t, res |
        res.each do |re|
          #debug "autodetection: trying = #{re} against #{login}"
          type = t if login.match(re)
        end
      end
      debug "autodetection: found type = #{type}"
      ## guessing makes Authentication failure tests fail -> no exception thrown
      if type.to_s == 'auto'    # no autodetection possible => resort to guessing
        othertypes = {}
        DOMAIN_RES.each {|k,v| othertypes[k] = TYPES[k] if v.empty? }  # collect providers with no regexp
        debug "guessing: trying #{othertypes.inspect}"
        if c = self.guess(login, password, {}, othertypes)
          return c
        else
          raise AuthenticationError
        end
      end
    elsif TYPES.include?(type.to_s.intern)
      TYPES[type.to_s.intern].new(login, password, options)
    else
      raise TypeNotFound, "#{type.inspect} is not a valid type, please choose one of the following: #{TYPES.keys.inspect}"
    end
  end
  
  def self.guess(login, password, options={}, types=TYPES)
    types.inject([]) do |a, t|
      begin
        a + t[1].new(login, password, options).contacts
      rescue AuthenticationError
        a
      end
    end.uniq
  end
end
