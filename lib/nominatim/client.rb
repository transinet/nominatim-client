require 'uri'
require 'nominatim/monitor'

module Nominatim
  class Client
    DEFAULT_ENDPOINT = 'http://nominatim.openstreetmap.org/'

    EXCEPTIONS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT,
                  JSON::ParserError, Monitor::ThresholdError, Timeout::Error]

    def initialize(options={})
      @options = options
      @monitor = Monitor.new
    end

    def configure(options)
      @options.merge!(options)
    end

    def reverse(latitude, longitude)
      uri = endpoint + 'reverse.php'
      uri.query = URI.encode_www_form(addressdetails: 1, format: 'json', lat: latitude, lon: longitude)

      @monitor.execute do
        Timeout.timeout(1) do
          Net::HTTP.start(uri.host, uri.port) do |http|
            http.open_timeout = 0.5
            http.read_timeout = 0.5

            request  = Net::HTTP::Get.new(uri)
            response = http.request(request)

            JSON.parse(response.body)
          end
        end
      end
    rescue *EXCEPTIONS
      nil
    end

    def search(text)
      uri = endpoint + 'search.php'
      uri.query = URI.encode_www_form(addressdetails: 1, format: 'json', q: text)

      Net::HTTP.start(uri.host, uri.port) do |http|
        request  = Net::HTTP::Get.new(uri)
        response = http.request(request)

        JSON.parse(response.body)
      end
    end

    private

    def endpoint
      URI(@options[:endpoint] || DEFAULT_ENDPOINT)
    end
  end
end
