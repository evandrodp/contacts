dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class WebdeContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:webde]
  end

  def test_login_success
    Contacts.new(:webde, @account.username, @account.password)
  end

  def test_login_failure
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:webde, @account.username, "wrong_password")
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:webde, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end
