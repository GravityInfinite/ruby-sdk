module GravityEngineData
  ##
  # SDK error
  GEAnalyticsError = Class.new(StandardError)

  ##
  # SDK error: illegal parameter
  IllegalParameterError = Class.new(GEAnalyticsError)

  ##
  # SDK error: connection error
  ConnectionError = Class.new(GEAnalyticsError)

  ##
  # SDK error: server error
  ServerError = Class.new(GEAnalyticsError)

  ##
  # Error handler
  #
  # e.g.
  #    class MyErrorHandler < GravityEngineData::GEErrorHandler
  #      def handle(error)
  #          puts error
  #          raise error
  #      end
  #    end
  #
  #    my_error_handler = MyErrorHandler.new
  #    tracker = GravityEngineData::GEAnalytics.new(consumer, my_error_handler)
  class GEErrorHandler
    ##
    # Override #handle to customize error handling
    def handle(error)
      false
    end
  end
end