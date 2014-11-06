# -*- encoding : utf-8 -*-
dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class GmxOldContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:gmx]
  end

  def test_fetch_contacts
    contacts = Contacts.new(:gmxold, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end
