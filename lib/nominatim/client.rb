require 'uri'
require 'json'
require 'net/http'
require 'nominatim/monitor'

module Nominatim
  class Client
    DEFAULTS = { endpoint: 'http://nominatim.openstreetmap.org/',
                 request_timeout: 1 }

    EXCEPTIONS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT,
                  JSON::ParserError, Monitor::ThresholdError, Timeout::Error]

    def initialize(options = {})
      @options = DEFAULTS.dup
      @monitor = Monitor.new
    end

    def configure(options)
      @options.merge!(options)
    end

    def reverse(latitude, longitude)
      request('reverse.php', lat: latitude, lon: longitude)
    end

    def search(text)
      request('search.php', q: text)
    end

    private

    def request(path, params)
      uri = uri(path, params)

      @monitor.execute do
        begin
          Timeout.timeout(@options[:request_timeout]) do
            Net::HTTP.start(uri.host, uri.port) do |http|
              request  = Net::HTTP::Get.new(uri)
              response = http.request(request)

              JSON.parse(response.body)
            end
          end
        rescue *EXCEPTIONS
          nil
        end
      end
    end

    def uri(path, params = {})
      uri = endpoint + path
      uri.query = URI.encode_www_form(params.merge(addressdetails: 1, format: :json))
      uri
    end

    def endpoint
      @endpoint ||= URI(@options[:endpoint])
    end
  end
end
