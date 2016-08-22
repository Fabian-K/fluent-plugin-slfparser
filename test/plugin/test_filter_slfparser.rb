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

    def test_add_tournament
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

  end
end