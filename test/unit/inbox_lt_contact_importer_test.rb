# -*- encoding : utf-8 -*-
dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class InboxLtContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:inbox_lt]
  end

  def test_guess_importer
    assert_equal Contacts::InboxLt, Contacts.guess_importer('test@inbox.lt')
  end

  def test_guess
    return unless @account
    contacts = Contacts.guess(@account.username, @account.password)
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end

  def test_successful_login
    Contacts.new(:inbox_lt, @account.username, @account.password)  if @account
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:inbox_lt, @account.username, "wrong_password")
    end  if @account
  end

  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:inbox_lt, @account.username, "")
    end if @account
  end

  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:inbox_lt, "", @account.password)
    end if @account
  end

  def test_fetch_contacts
    if @account
      contacts = Contacts.new(:inbox_lt, @account.username, @account.password).contacts
      @account.contacts.each do |contact|
        assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
      end
    end
  end
end
