# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'contacts'

class HotmailContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:hotmail]
  end

  def test_guess_importer
    assert_equal Contacts::Hotmail, Contacts.guess_importer('test@hotmail.com')
    assert_equal Contacts::Hotmail, Contacts.guess_importer('test@hotmail.de')
    assert_equal Contacts::Hotmail, Contacts.guess_importer('test@live.de')
  end

  def test_guess
    return unless @account
    contacts = Contacts.guess(@account.username, @account.password)
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end

  def test_successful_login
    Contacts.new(:hotmail, @account.username, @account.password)
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:hotmail, @account.username,"wrong_password")
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:hotmail, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end

  def test_importer_fails_with_invalid_msn_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:hotmail, "test@msn.com","wrong_password")
    end
  end

  # Since the hotmail scraper doesn't read names, test email
  def test_fetch_email
    contacts = Contacts.new(:hotmail, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.any?{|book_contact| book_contact.last == contact.last }, "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end

