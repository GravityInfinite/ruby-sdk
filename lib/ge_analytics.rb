require 'securerandom'
require 'ge_errors'
require 'ge_version'
require 'time'

##
# GravityEngineData module
module GravityEngineData
  @is_enable_log = false

  ##
  # Enable SDK log or not
  # @param enable [Boolean] true or false
  def self.set_enable_log(enable)
    unless [true, false].include? enable
      enable = false
    end
    @is_enable_log = enable
  end

  ##
  # Get log status
  # @return [Boolean] enable or not
  def self.get_enable_log
    @is_enable_log
  end

  # Analytics class. Provides the function of tracking data
  class GEAnalytics

    ##
    # Init function
    #   @param consumer [consumer] data consumer: GELoggerConsumer | GEDebugConsumer | GEBatchConsumer
    #   @param error_handler [GEErrorHandler] custom error handler, process SDK error. It could be nil
    def initialize(consumer, error_handler = nil, uuid: false)
      @error_handler = error_handler || GEErrorHandler.new
      @consumer = consumer
      GELog.info("SDK init success.")
    end

    ##
    # Report ordinary event
    #   event_name: (require) A string of 50 letters and digits that starts with '#' or a letter
    #   client_id:  client ID
    #   properties:  string, number, Time, boolean
    def track(event_name: nil, client_id: nil, properties: {})
      if event_name.nil? || event_name.to_s.empty?
        raise IllegalParameterError.new("event_name is required for track events and cannot be empty.")
      end
      _internal_track(:track, event_name: event_name, client_id: client_id, properties: properties)
    end

    ##
    # Set user properties. would overwrite existing names
    #   client_id:  client ID
    #   properties:  string, number, Time, boolean
    def user_set(client_id: nil, properties: {})
      _internal_track(:profile_set, client_id: client_id, properties: properties)
    end

    ##
    # Set user properties, If such property had been set before, this message would be neglected
    #   client_id:  client ID
    #   properties:  string, number, Time, boolean
    def user_set_once(client_id: nil, properties: {})
      _internal_track(:profile_set_once,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # To append user properties of array type
    #   client_id:  client ID
    #   properties:  string, number
    def user_append(client_id: nil, properties: {})
      _internal_track(:profile_append,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # To append user properties of array type. It filters out duplicate values
    #   client_id:  client ID
    #   properties:  string, number
    def user_uniq_append(client_id: nil, properties: {})
      _internal_track(:profile_uniq_append,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # Clear the user properties of users
    #   client_id:  client ID
    #   properties:  string, number, Time, boolean
    def user_unset(client_id: nil, properties: nil)
      _internal_track(:profile_unset,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # To accumulate operations against the property
    #   client_id:  client ID
    #   properties:  number
    def user_increment(client_id: nil, properties: {})
      _internal_track(:profile_increment,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # To set max val against the property
    #   client_id:  client ID
    #   properties:  number
    def user_max(client_id: nil, properties: {})
      _internal_track(:profile_number_max,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # To set min val against the property
    #   client_id:  client ID
    #   properties:  number
    def user_min(client_id: nil, properties: {})
      _internal_track(:profile_number_min,
                      client_id: client_id,
                      properties: properties,
      )
    end

    ##
    # Delete a user, This operation cannot be undone
    #   client_id:  client ID
    def user_del(client_id: nil)
      _internal_track(:profile_delete,
                      client_id: client_id,
      )
    end

    ##
    # Report data immediately
    def flush
      GELog.info("SDK flush data.")
      return true unless @consumer.respond_to?(:flush)
      ret = true
      begin
        @consumer.flush
      rescue GEAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end
      ret
    end

    ##
    # Close and exit sdk
    def close
      return true unless @consumer.respond_to?(:close)
      ret = true
      begin
        @consumer.close
      rescue GEAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end

      GELog.info("SDK close.")
      ret
    end

    private

    def _internal_track(type, properties: {}, event_name: nil, client_id: nil)
      if client_id.nil? || client_id.to_s.empty?
        raise IllegalParameterError.new("client_id is required and cannot be empty.")
      end

      ms = Time.now.to_f * 1000
      evt = {
        'client_id' => client_id,
      }

      if type == :track
        properties['$lib'] = 'ruby'
        properties['$lib_version'] = GravityEngineData::VERSION
      else
        event_name = type.to_s
        type = 'profile'
      end

      # Ensure type is always a String for consistent JSON serialization
      p = {
        'type' => type.to_s,
        'event' => event_name.is_a?(Symbol) ? event_name.to_s : event_name,
        'time' => ms.to_i,
        'properties' => properties,
      }
      evt['event_list'] = [p]
      ret = true
      begin
        @consumer.add(evt)
      rescue GEAnalyticsError => e
        @error_handler.handle(e)
        ret = false
      end
      ret
    end
  end

  ##
  # SDK log module
  class GELog
    def self.info(*msg)
      if GravityEngineData::get_enable_log
        print("[GravityEngineData][#{Time.now}] ")
        puts(msg)
      end
    end
  end
end
