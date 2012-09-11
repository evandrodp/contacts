# -*- encoding : utf-8 -*-
dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class GmxContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:gmx]
  end

  def test_login_success
    Contacts.new(:gmx, @account.username, @account.password)
  end

  def test_autodetection_success
    Contacts.new(:auto, @account.username, @account.password)
  end

  def test_login_failure
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:gmx, @account.username, "wrong_password")
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:gmx, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end
