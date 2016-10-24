require 'helper'

class Fluent::SLFParserFilterTest < Test::Unit::TestCase

  # through & merge
  CONFIG1 = %[
type slfparser
]

  def setup
    omit("Use fluentd v0.12 or later") unless defined?(Fluent::Filter)

    Fluent::Test.setup
  end

  def create_driver(conf=CONFIG1, tag='test')
    Fluent::Test::FilterTestDriver.new(Fluent::SLFParserFilter, tag).configure(conf)
  end

  class TestConfigure < self

    def test_java_backend_log
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i

      d.run do
        d.filter({'log' => "[Thread-10] INFO de.kajzar.common.backend.sync.sns.AmazonServices - Push to arn:aws:sns:eu-west-1:359809564747:CPP-BUNDESLIGA-PROD-Game-FCBBMG",
                  'source' => 'stderr',
                  'container_name' => "/k8s_bl-backend.a8965ab_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_a98b5cb6",
                  'container_id' => "fb1b809201545b179ff0263bd903a470b1b8ad80cbe9cd5560aa432cfc3d4e4a"}, time)
      end

      filtered = d.filtered_as_array # // [tag, timestamp, hashmap]
      m = filtered[0][2];

      # don´t modify existing fields
      assert_equal 'stderr', m['source']
      assert_equal '[Thread-10] INFO de.kajzar.common.backend.sync.sns.AmazonServices - Push to arn:aws:sns:eu-west-1:359809564747:CPP-BUNDESLIGA-PROD-Game-FCBBMG', m['log']
      assert_equal '/k8s_bl-backend.a8965ab_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_a98b5cb6', m['container_name']
      assert_equal 'fb1b809201545b179ff0263bd903a470b1b8ad80cbe9cd5560aa432cfc3d4e4a', m['container_id']

      assert_equal 'bundesliga', m['tournament']
      assert_equal 'java-backend', m['type']
      assert_equal 'Thread-10', m['java-thread']
      assert_equal 'INFO', m['severity']
      assert_equal 'de.kajzar.common.backend.sync.sns.AmazonServices', m['java-logger']
      assert_equal time, m['time']
    end


    def test_ignore_other_logs
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i

      d.run do
        d.filter({'log' => "AnyLog",
                  'source' => 'stderr',
                  'container_name' => "/any_container_name",
                  'container_id' => "fb1b809201545b179ff0263bd903a470b1b8ad80cbe9cd5560aa432cfc3d4e4a"}, time)
      end

      filtered = d.filtered_as_array # // [tag, timestamp, hashmap]
      m = filtered[0][2];

      # don´t modify existing fields
      assert_equal 'stderr', m['source']
      assert_equal 'AnyLog', m['log']
      assert_equal '/any_container_name', m['container_name']
      assert_equal 'fb1b809201545b179ff0263bd903a470b1b8ad80cbe9cd5560aa432cfc3d4e4a', m['container_id']
    end

    def test_parse_http_log_200
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i

      d.run do
        d.filter({'log' => '92.208.119.63 - - [02/Oct/2016:16:26:32 +0000] "GET /api/device/sync?clientDataVersion=2884 HTTP/1.1" 200 39 "-" "okhttp/2.7.5" "-"',
                  'source' => 'stdout',
                  'container_name' => "/k8s_router.3c190b01_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_df360a04",
                  'container_id' => "f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907"}, time)
      end

      filtered = d.filtered_as_array # // [tag, timestamp, hashmap]
      m = filtered[0][2];

      # don´t modify existing fields
      assert_equal 'stdout', m['source']
      assert_equal '92.208.119.63 - - [02/Oct/2016:16:26:32 +0000] "GET /api/device/sync?clientDataVersion=2884 HTTP/1.1" 200 39 "-" "okhttp/2.7.5" "-"', m['log']
      assert_equal '/k8s_router.3c190b01_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_df360a04', m['container_name']
      assert_equal 'f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907', m['container_id']
      assert_equal 'java-router', m['type']
      assert_equal '200', m['http_status']
      assert_equal 'INFO', m['severity']
    end

    def test_parse_http_log_uptime
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i

      d.run do
        d.filter({'log' => '104.155.110.139 - - [24/Oct/2016:04:03:17 +0000] "GET /api/status HTTP/1.1" 200 2 "-" "GoogleStackdriverMonitoring-UptimeChecks(https://cloud.google.com/monitoring)" "-"',
                  'source' => 'stdout',
                  'container_name' => "/k8s_router.3c190b01_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_df360a04",
                  'container_id' => "f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907"}, time)
      end

      filtered = d.filtered_as_array # // [tag, timestamp, hashmap]
      m = filtered[0][2];

      # don´t modify existing fields
      assert_equal 'stdout', m['source']
      assert_equal '104.155.110.139 - - [24/Oct/2016:04:03:17 +0000] "GET /api/status HTTP/1.1" 200 2 "-" "GoogleStackdriverMonitoring-UptimeChecks(https://cloud.google.com/monitoring)" "-"', m['log']
      assert_equal '/k8s_router.3c190b01_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_df360a04', m['container_name']
      assert_equal 'f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907', m['container_id']
      assert_equal 'java-router', m['type']
      assert_equal 'DEBUG', m['severity']

      # http specific
      assert_equal '200', m['http_status']
      assert_equal 'GET', m['http_method']
      assert_equal '/api/status', m['http_request']
      assert_equal '2', m['http_bytes']
      assert_equal 'GoogleStackdriverMonitoring-UptimeChecks(https://cloud.google.com/monitoring)', m['http_user_agent']
    end

    def test_parse_http_log_500
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i

      d.run do
        d.filter({'log' => '109.42.3.174 - - [02/Oct/2016:15:07:59 +0000] "POST /api/fankurve/game/delete HTTP/1.1" 500 0 "-" "okhttp/2.7.5" "-"',
                  'source' => 'stdout',
                  'container_name' => "/k8s_router.3c190b01_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_df360a04",
                  'container_id' => "f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907"}, time)
      end

      filtered = d.filtered_as_array # // [tag, timestamp, hashmap]
      m = filtered[0][2];

      # don´t modify existing fields
      assert_equal 'stdout', m['source']
      assert_equal '109.42.3.174 - - [02/Oct/2016:15:07:59 +0000] "POST /api/fankurve/game/delete HTTP/1.1" 500 0 "-" "okhttp/2.7.5" "-"', m['log']
      assert_equal '/k8s_router.3c190b01_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_df360a04', m['container_name']
      assert_equal 'f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907', m['container_id']
      assert_equal 'java-router', m['type']
      assert_equal '500', m['http_status']
      assert_equal 'WARNING', m['severity']
    end

    def test_gc_log_message
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i

      d.run do
        d.filter({'log' => '[GC (Allocation Failure) [DefNew: 18334K->294K(19840K), 0.0101717 secs] 36294K->18260K(63552K), 0.0126504 secs] [Times: user=0.01 sys=0.00, real=0.01 secs]',
                  'source' => 'stdout',
                  'container_name' => "/k8s_l3-backend.96d460e4_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_ee4a73e4",
                  'container_id' => "f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907"}, time)
      end

      filtered = d.filtered_as_array # // [tag, timestamp, hashmap]
      m = filtered[0][2];

      # don´t modify existing fields
      assert_equal 'stdout', m['source']
      assert_equal '[GC (Allocation Failure) [DefNew: 18334K->294K(19840K), 0.0101717 secs] 36294K->18260K(63552K), 0.0126504 secs] [Times: user=0.01 sys=0.00, real=0.01 secs]', m['log']
      assert_equal '/k8s_l3-backend.96d460e4_battleship-battleship_default_2e46cb2d2a6b3ce2ac5412d5f78422cf_ee4a73e4', m['container_name']
      assert_equal 'f1017b62aee6a36506871909a5d85a0817b3c081cd29c977579fc4142e6e1907', m['container_id']
      assert_equal 'java-backend', m['type']
      assert_equal 'liga3', m['tournament']
      assert_equal 'DEBUG', m['severity']
      assert_equal 'GarbageCollection', m['java-logger']
    end


  end
end