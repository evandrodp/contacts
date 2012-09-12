dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class TonlineDeContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:tonline_de]
  end

  def test_guess_importer
    assert_equal Contacts::TonlineDe, Contacts.guess_importer('test@t-online.de')
    assert_equal Contacts::TonlineDe, Contacts.guess_importer('test@t-mobile.de')
  end

  def test_successful_login
    Contacts.new(:tonline_de, @account.username, @account.password)
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:tonline_de, @account.username, "wrong_password")
    end
  end

  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:tonline_de, @account.username, "")
    end
  end

  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:tonline_de, "", @account.password)
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:tonline_de, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end