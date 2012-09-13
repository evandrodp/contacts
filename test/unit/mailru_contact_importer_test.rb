# -*- encoding : utf-8 -*-
dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class MailruContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:mailru]
  end

  def test_guess_importer
    assert_equal Contacts::Mailru, Contacts.guess_importer('test@mail.ru')
    assert_equal Contacts::Mailru, Contacts.guess_importer('test@list.ru')
    assert_equal Contacts::Mailru, Contacts.guess_importer('test@inbox.ru')
    assert_equal Contacts::Mailru, Contacts.guess_importer('test@bk.ru')
  end

  def test_successful_login
    Contacts.new(:mailru, @account.username, @account.password)  if @account
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:mailru, @account.username, "wrong_password")
    end if @account
  end

  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:mailru, @account.username, "")
    end if @account
  end

  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:mailru, "", @account.password)
    end if @account
  end

  def test_fetch_contacts
    if @account
      contacts = Contacts.new(:mailru, @account.username, @account.password).contacts  if @account
      @account.contacts.each do |contact|
        assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
      end
    end
  end
end
