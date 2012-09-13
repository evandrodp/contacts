Gem::Specification.new do |s|
  s.name = "contacts"
  s.version = "1.2.22"
  s.date = "2012-09-13"
  s.platform = Gem::Platform::RUBY
  s.summary = "A universal interface to grab contact list information from various providers including Yahoo, AOL, Gmail, Hotmail, Plaxo, GMX.net, Web.de, inbox.lt, seznam.cz, t-online.de. Now supporting Ruby 1.9."
  s.email = ["jens-github@spamfreemail.de", "lucas@rufy.com"]
  s.homepage = "http://github.com/jensb/contacts"
  s.description = "A universal interface to grab contact list information from various providers including Yahoo, AOL, Gmail, Hotmail, and Plaxo."
  s.has_rdoc = false
  s.authors = ["Jens Benecke", "Lucas Carlson", "Brad Imbierowicz", "Wong Liang Zan", "Mateusz Konikowski", "Laurynas Butkus"]
  s.files = Dir.glob("lib/**/*") + Dir.glob("examples/**/*") + %w(LICENSE README.rdoc Rakefile)
  s.add_dependency("json", "~> 1.7.3")
  s.add_dependency('gdata_19', '~> 1.1.3')
  s.add_dependency('nokogiri', '~> 1.5.0')
end
