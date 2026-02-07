require 'test_helper'

class AirrecordTest < Minitest::Test
  def test_set_api_key
    Airrecord.api_key = "walrus"
    assert_equal "walrus", Airrecord.api_key
  end

  def test_set_api_uri
    Airrecord.api_uri = "https://custom.airtable.example.com"
    assert_equal "https://custom.airtable.example.com", Airrecord.api_uri
    assert_equal "https://custom.airtable.example.com", Airrecord::Client.api_uri.to_s
  ensure
    Airrecord.api_uri = nil
  end
end
