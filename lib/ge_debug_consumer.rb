require 'json'
require 'net/http'

module GravityEngineData
  ##
  # The data is reported one by one, and when an error occurs, the log will be printed on the console.
  class GEDebugConsumer

    ##
    # Init debug consumer
    #   @param server_url: server url
    #   @param callback: global error callback, invoked when report failed; receives (err, client_id)
    def initialize(server_url, callback = nil)
      @server_url = server_url
      @callback = callback
      GELog.info("GEDebugConsumer init success. ServerUrl: #{server_url}")
    end

    def add(message)
      msg_json_str = message.to_json
      client_id = message.is_a?(Hash) ? message['client_id'] : nil
      GELog.info("Send data to server.")
      headers = {
        "Content-Type" => "application/json"
      }
      begin
        response_code, response_body = request(@server_url, msg_json_str, headers)
        GELog.info("Send data, response: #{response_body}")
      rescue => e
        err = ConnectionError.new("Could not connect to GE server, with error \"#{e.message}\".")
        report_error(err, client_id)
        raise err
      end

      result = {}
      if response_code.to_i == 200
        begin
          result = JSON.parse(response_body.to_s)
        rescue JSON::JSONError => e
          report_error(e, client_id)
          raise ServerError.new("Could not interpret GE server response: '#{response_body}'")
        end
      end
      if result['code'] != 0
        err = ServerError.new("Could not write to GE, server responded with #{response_code} returning: '#{response_body}'")
        report_error(err, client_id)
        raise err
      end
    end

    private

    ##
    # Invoke the global error callback when report failed
    def report_error(err, client_id)
      return if @callback.nil?
      begin
        @callback.call(err, client_id)
      rescue => e
        GELog.error("error callback failed: #{e.message}")
      end
    end

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
