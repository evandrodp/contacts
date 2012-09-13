# -*- encoding : utf-8 -*-
dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class OneltContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:onelt]
  end

  def test_guess_importer
    assert_equal Contacts::Onelt, Contacts.guess_importer('test@one.lt')
  end

  def test_successful_login
    Contacts.new(:onelt, @account.username, @account.password) if @account
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:onelt, @account.username, "wrong_password")
    end  if @account
  end

  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:onelt, @account.username, "")
    end  if @account
  end

  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:onelt, "", @account.password)
    end  if @account
  end

  def test_fetch_contacts
    if @account
      contacts = Contacts.new(:onelt, @account.username, @account.password).contacts
      @account.contacts.each do |contact|
        assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
      end
    end
  end
end
