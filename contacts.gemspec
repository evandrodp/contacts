Gem::Specification.new do |s|
  s.name = "contacts"
  s.version = "1.2.4"
  s.date = "2011-12-04"
  s.summary = "A universal interface to grab contact list information from various providers including Yahoo, AOL, Gmail, Hotmail, and Plaxo."
  s.email = ["jens-github@spamfreemail.de", "lucas@rufy.com"]
  s.homepage = "http://github.com/cardmagic/contacts"
  s.description = "A universal interface to grab contact list information from various providers including Yahoo, AOL, Gmail, Hotmail, and Plaxo."
  s.has_rdoc = false
  s.authors = ["Jens Benecke", "Lucas Carlson"]
  s.files = ["LICENSE", "Rakefile", "README", "examples/grab_contacts.rb", "lib/contacts.rb", "lib/contacts/base.rb", "lib/contacts/json_picker.rb", "lib/contacts/gmail.rb", "lib/contacts/aol.rb", "lib/contacts/hotmail.rb", "lib/contacts/plaxo.rb", "lib/contacts/yahoo.rb", "lib/contacts/webde.rb", "lib/contacts/gmx.rb"]
  s.add_dependency("json", ">= 1.1.1")
  s.add_dependency('gdata', '>= 1.1.1')
end
