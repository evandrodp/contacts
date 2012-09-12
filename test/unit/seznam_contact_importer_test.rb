dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class SeznamContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:seznam]
  end

  def test_guess_importer
    assert_equal Contacts::Seznam, Contacts.guess_importer('test@seznam.cz')
    assert_equal Contacts::Seznam, Contacts.guess_importer('test@email.cz')
    assert_equal Contacts::Seznam, Contacts.guess_importer('test@post.cz')
    assert_equal Contacts::Seznam, Contacts.guess_importer('test@spoluzaci.cz')
    assert_equal Contacts::Seznam, Contacts.guess_importer('test@stream.cz')
    assert_equal Contacts::Seznam, Contacts.guess_importer('test@firmy.cz')
  end

  def test_successful_login
    Contacts.new(:seznam, @account.username, @account.password)
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:seznam, @account.username, "wrong_password")
    end
  end

  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:seznam, @account.username, "")
    end
  end

  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:seznam, "", @account.password)
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:seznam, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end