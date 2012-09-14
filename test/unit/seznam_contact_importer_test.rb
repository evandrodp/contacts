# -*- encoding : utf-8 -*-
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

  def test_guess
    return unless @account
    contacts = Contacts.guess(@account.username, @account.password)
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end

  def test_successful_login
    Contacts.new(:seznam, @account.username, @account.password)  if @account
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:seznam, @account.username, "wrong_password")
    end if @account
  end

  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:seznam, @account.username, "")
    end if @account
  end

  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:seznam, "", @account.password)
    end if @account
  end

  def test_fetch_contacts
    if @account
      contacts = Contacts.new(:seznam, @account.username, @account.password).contacts if @account
      @account.contacts.each do |contact|
        assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
      end
    end
  end
end
