# -*- encoding : utf-8 -*-
require 'gdata'

class Contacts
  class Gmail < Base
    
    DETECTED_DOMAINS = [ /gmail.com/i, /googlemail.com/i ]
    CONTACTS_SCOPE = 'http://www.google.com/m8/feeds/'
    CONTACTS_FEED = CONTACTS_SCOPE + 'contacts/default/full/?max-results=1000'
    
    def contacts
      return @contacts if @contacts
    end
    
    def real_connect
      @client = GData::Client::Contacts.new
      @client.clientlogin(@login, @password, @captcha_token, @captcha_response)
      
      feed = @client.get(CONTACTS_FEED).to_xml
      
      @contacts = feed.elements.to_a('entry').collect do |entry|
        title, email = entry.elements['title'].text, nil
        primary_email = nil

        entry.elements.each('gd:email') do |e|
          if e.attribute('primary')
            primary_email = e.attribute('address').value 
          else
            email = e.attribute('address').value 
          end
        end

        email = primary_email unless primary_email.nil?

        [title, email] unless email.nil?
      end
      @contacts.compact!
    rescue GData::Client::AuthorizationError => e
      raise AuthenticationError, "Username or password are incorrect"
    end
    
    private
    
    TYPES[:gmail] = Gmail
    NAMES[:gmail] = "Google Mail"
  end
end
