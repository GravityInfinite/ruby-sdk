require 'json'
require 'net/http'
require 'stringio'
require 'zlib'

module GravityEngineData
  ##
  # Upload data by http
  class GEBatchConsumer

    # buffer count
    DEFAULT_LENGTH = 20
    MAX_LENGTH = 2000

    ##
    # Init batch consumer
    def initialize(server_url, max_buffer_length = DEFAULT_LENGTH)
      @server_url = server_url
      @compress = true
      @max_length = [max_buffer_length, MAX_LENGTH].min
      @buffers = []
      GELog.info("GEBatchConsumer init success. ServerUrl: #{server_url}")
    end

    ##
    # http request compress
    # @param compress [Boolean] compress or not
    def set_compress(compress)
      @compress = compress
    end

    def add(message)
      GELog.info("Enqueue data to buffer. buffer size: #{@buffers.length}")
      @buffers << message
      flush if @buffers.length >= @max_length
    end

    def close
      flush
      GELog.info("GEBatchConsumer close.")
    end

    def flush
      GELog.info("GEBatchConsumer flush data.")
      until @buffers.empty?
        chunk = @buffers.shift(@max_length)
        evt_map = {}
        chunk.each do |item|
          client_id = item['client_id']
          event_list = item['event_list']
          if evt_map[client_id].nil?
            evt_map[client_id] = event_list
          else
            evt_map[client_id] = evt_map[client_id] + event_list
          end
        end
        evt_map.each do |client_id, event_list|
          request_body = {
            client_id: client_id,
            event_list: event_list
          }
          if @compress
            wio = StringIO.new("w")
            gzip_io = Zlib::GzipWriter.new(wio)
            gzip_io.write(request_body.to_json)
            gzip_io.close
            data = wio.string
          else
            data = request_body.to_json
          end
          compress_type = @compress ? 'gzip' : 'none'
          headers = { 'Gravity-Content-Compress' => compress_type }
          GELog.info("Send data to server.")
          response_code, response_body = _request(@server_url, data, headers)
          GELog.info("Send data, response: #{response_body}")

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
      end
    end

    private

    def _request(server_url, body_data, headers)
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
