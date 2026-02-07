require_relative 'faraday_rate_limiter'
require 'erb'

module Airrecord
  class Client
    attr_reader :api_key
    attr_writer :connection

    # Per Airtable's documentation you will get throttled for 30 seconds if you
    # issue more than 5 requests per second. Airrecord is a good citizen.
    AIRTABLE_RPS_LIMIT = 5

    def initialize(api_key)
      @api_key = api_key
    end

    def self.api_uri=(uri)
      @api_uri = URI.parse(uri)
    end

    def self.api_uri
      if Airrecord.respond_to?(:api_uri) && Airrecord.api_uri
        uri = Airrecord.api_uri
        uri.is_a?(URI) ? uri : URI.parse(uri.to_s)
      else
        @api_uri || URI.parse("https://api.airtable.com")
      end
    end

    def connection
      # Don't cache connection when using Airrecord.api_uri so that changing it takes effect
      if Airrecord.respond_to?(:api_uri) && Airrecord.api_uri
        build_connection
      else
        @connection ||= build_connection
      end
    end

    def build_connection
      Faraday.new(
        url: self.class.api_uri,
        headers: {
          "Authorization" => "Bearer #{api_key}",
          "User-Agent"    => "Airrecord/#{Airrecord::VERSION}",
        },
      ) do |conn|
        if Airrecord.throttle?
          conn.request :airrecord_rate_limiter, requests_per_second: AIRTABLE_RPS_LIMIT
        end
        conn.adapter :net_http_persistent
      end
    end

    def escape(*args)
      ERB::Util.url_encode(*args)
    end

    def parse(body)
      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def handle_error(status, error)
      if error.is_a?(Hash) && error['error']
        raise Error, "HTTP #{status}: #{error['error']['type']}: #{error['error']['message']}"
      else
        raise Error, "HTTP #{status}: Communication error: #{error}"
      end
    end
  end
end
