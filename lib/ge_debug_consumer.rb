require 'json'
require 'net/http'

module GravityEngineData
  ##
  # The data is reported one by one, and when an error occurs, the log will be printed on the console.
  class GEDebugConsumer

    ##
    # Init debug consumer
    #   @param server_url: server url
    def initialize(server_url)
      @server_url = server_url
      GELog.info("GEDebugConsumer init success. ServerUrl: #{server_url}")
    end

    def add(message)
      msg_json_str = message.to_json
      GELog.info("Send data to server.")
      headers = {
        "Content-Type" => "application/json"
      }
      begin
        response_code, response_body = request(@server_url, msg_json_str, headers)
        GELog.info("Send data, response: #{response_body}")
      rescue => e
        raise ConnectionError.new("Could not connect to GE server, with error \"#{e.message}\".")
      end

      result = {}
      if response_code.to_i == 200
        begin
          result = JSON.parse(response_body.to_s)
        rescue JSON::JSONError
          raise ServerError.new("Could not interpret GE server response: '#{response_body}'")
        end
      end
      if result['code'] != 0
        raise ServerError.new("Could not write to GE, server responded with #{response_code} returning: '#{response_body}'")
      end
    end

    private

    def request(server_url, body_data, headers)
      uri = URI.parse(server_url)
      request = Net::HTTP::Post.new(uri, headers)
      request.body = body_data

      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = (uri.scheme == 'https')
      if client.use_ssl?
        client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      client.open_timeout = 10
      client.continue_timeout = 10
      client.read_timeout = 10
      client.ssl_timeout = 10

      response = client.request(request)
      [response.code, response.body]
    end
  end
end
