$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'gravity-engine-data'
require 'time'

if __FILE__ == $0

  CLIENT_ID = '_test_client_id_0'
  SERVER_URL = 'https://backend.gravity-engine.com/event_center/api/v1/event/collect/?access_token=___XXX___'

  class MyErrorHandler < GravityEngineData::GEErrorHandler
    def handle(error)
      puts error
      raise error
    end
  end

  def debug_consumer
    GravityEngineData::GEDebugConsumer.new(SERVER_URL)
  end

  def batch_consumer
    consumer = GravityEngineData::GEBatchConsumer.new(SERVER_URL, 4)
    consumer.set_compress(true)
    consumer
  end

  GravityEngineData::set_enable_log(true)
  my_error_handler = MyErrorHandler.new

  ge_sdk = GravityEngineData::GEAnalytics.new(debug_consumer, my_error_handler)
  # ge_sdk = GravityEngineData::GEAnalytics.new(batch_consumer, my_error_handler)


  $i = 0
  $num = 10

  while $i < $num  do
    puts $i
    $i +=1
    properties = {
      array: ["str1", "11", Time.now, "2020-02-11 17:02:52.415"],
      prop_date: Time.now,
      prop_double: 134.1,
      prop_string: 'hello world',
      prop_bool: true,
      idx: $i,
    }
    ge_sdk.track(event_name: '$AdClick',  client_id: CLIENT_ID, properties: properties)
  end

  user_data = {
    array: ["str1-idx", 11, 22.22],
    prop_date: Time.now,
    prop_double: 134.12,
    prop_string: 'hello',
    prop_int: 666,
  }
  ge_sdk.user_set(client_id: CLIENT_ID, properties: user_data)

  user_append_data = {
    'prop_list_type'=> Array.[]("a", "b", "a")
  }
  ge_sdk.user_append(client_id: CLIENT_ID, properties: user_append_data)

  user_uniq_append_data = {
    'prop_list_type'=> Array.[]("a", "b", "a")
  }
  ge_sdk.user_uniq_append(client_id: CLIENT_ID, properties: user_uniq_append_data)

  user_set_once_data = {
    'prop_set_once'=> 'xxx',
  }
  ge_sdk.user_set_once(client_id: CLIENT_ID, properties: user_set_once_data)

  ge_sdk.user_increment(client_id: CLIENT_ID, properties: {'TotalRevenue'=> 648})

  ge_sdk.user_min(client_id: CLIENT_ID, properties: {'TotalRevenue'=> 1})

  ge_sdk.user_max(client_id: CLIENT_ID, properties: {'TotalRevenue'=> 1000})

  ge_sdk.user_set(client_id: CLIENT_ID, properties:  {'user_name'=> 'xxx'})

  ge_sdk.user_unset(client_id: CLIENT_ID, properties: {'user_name'=> ''})

  ge_sdk.user_del(client_id: CLIENT_ID)

  ge_sdk.flush

  ge_sdk.close
end