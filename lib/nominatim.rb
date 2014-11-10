require 'nominatim/version'
require 'nominatim/client'
require 'nominatim/monitor'

require 'uri'
require 'forwardable'

module Nominatim
  extend SingleForwardable

  def_delegators :client, :configure, :reverse, :search

  def self.client
    @client ||= Client.new
  end
end
