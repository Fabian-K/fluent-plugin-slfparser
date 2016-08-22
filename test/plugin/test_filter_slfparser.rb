require 'helper'

class Fluent::WootheeFilterTest < Test::Unit::TestCase

  # through & merge
  CONFIG1 = %[
type woothee
key_name agent
merge_agent_info yes
]

  def setup
    omit("Use fluentd v0.12 or later") unless defined?(Fluent::Filter)

    Fluent::Test.setup
  end

  def create_driver(conf=CONFIG1, tag='test')
    Fluent::Test::FilterTestDriver.new(Fluent::WootheeFilter, tag).configure(conf)
  end

  class TestConfigure < self

    def test_through_and_merge
      d = create_driver CONFIG1
      assert_equal false, d.instance.fast_crawler_filter_mode
      assert_equal 'agent', d.instance.key_name

      assert_equal 0, d.instance.filter_categories.size
      assert_equal 0, d.instance.drop_categories.size
      assert_equal :through, d.instance.mode

      assert_equal true, d.instance.merge_agent_info
      assert_equal 'agent_name', d.instance.out_key_name
      assert_equal 'agent_category', d.instance.out_key_category
      assert_equal 'agent_os', d.instance.out_key_os
      assert_nil d.instance.out_key_version
      assert_nil d.instance.out_key_vendor
    end


    # through & merge
    def test_filter_through
      d = create_driver(CONFIG1, 'test.message')
      time = Time.parse('2012-07-20 16:40:30').to_i
      d.run do
        d.filter({'value' => 0, 'agent' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Win64; x64; Trident/6.0)'}, time)
        d.filter({'value' => 1, 'agent' => 'Mozilla/5.0 (Windows NT 6.0; rv:9.0.1) Gecko/20100101 Firefox/9.0.1'}, time)
        d.filter({'value' => 2, 'agent' => 'Mozilla/5.0 (Ubuntu; X11; Linux i686; rv:9.0.1) Gecko/20100101 Firefox/9.0.1'}, time)
        d.filter({'value' => 3, 'agent' => 'Mozilla/5.0 (Linux; U; Android 3.1; ja-jp; L-06C Build/HMJ37) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13'}, time)
        d.filter({'value' => 4, 'agent' => 'DoCoMo/1.0/N505i/c20/TB/W24H12'}, time)
        d.filter({'value' => 5, 'agent' => 'Mozilla/5.0 (PlayStation Vita 1.51) AppleWebKit/531.22.8 (KHTML, like Gecko) Silk/3.2'}, time)
        d.filter({'value' => 6, 'agent' => 'Mozilla/5.0 (compatible; Google Desktop/5.9.1005.12335; http://desktop.google.com/)'}, time)
        d.filter({'value' => 7, 'agent' => 'msnbot/1.1 (+http://search.msn.com/msnbot.htm)'}, time)
      end

      filtered = d.filtered_as_array
      assert_equal 8, filtered.size
      assert_equal 'test.message', filtered[0][0]
      assert_equal time, filtered[0][1]

      # 'agent' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Win64; x64; Trident/6.0)'
      m = filtered[0][2]
      assert_equal 0, m['value']
      assert_equal 'Internet Explorer', m['agent_name']
      assert_equal 'pc', m['agent_category']
      assert_equal 'Windows 8', m['agent_os']
      assert_equal 5, m.keys.size

      # 'agent' => 'Mozilla/5.0 (Windows NT 6.0; rv:9.0.1) Gecko/20100101 Firefox/9.0.1'
      m = filtered[1][2]
      assert_equal 1, m['value']
      assert_equal 'Firefox', m['agent_name']
      assert_equal 'pc', m['agent_category']
      assert_equal 'Windows Vista', m['agent_os']

      # 'agent' => 'Mozilla/5.0 (Ubuntu; X11; Linux i686; rv:9.0.1) Gecko/20100101 Firefox/9.0.1'
      m = filtered[2][2]
      assert_equal 2, m['value']
      assert_equal 'Firefox', m['agent_name']
      assert_equal 'pc', m['agent_category']
      assert_equal 'Linux', m['agent_os']

      # 'agent' => 'Mozilla/5.0 (Linux; U; Android 3.1; ja-jp; L-06C Build/HMJ37) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13'
      m = filtered[3][2]
      assert_equal 3, m['value']
      assert_equal 'Safari', m['agent_name']
      assert_equal 'smartphone', m['agent_category']
      assert_equal 'Android', m['agent_os']

      # 'agent' => 'DoCoMo/1.0/N505i/c20/TB/W24H12'
      m = filtered[4][2]
      assert_equal 4, m['value']
      assert_equal 'docomo', m['agent_name']
      assert_equal 'mobilephone', m['agent_category']
      assert_equal 'docomo', m['agent_os']

      # 'agent' => 'Mozilla/5.0 (PlayStation Vita 1.51) AppleWebKit/531.22.8 (KHTML, like Gecko) Silk/3.2'
      m = filtered[5][2]
      assert_equal 5, m['value']
      assert_equal 'PlayStation Vita', m['agent_name']
      assert_equal 'appliance', m['agent_category']
      assert_equal 'PlayStation Vita', m['agent_os']

      # 'agent' => 'Mozilla/5.0 (compatible; Google Desktop/5.9.1005.12335; http://desktop.google.com/)'
      m = filtered[6][2]
      assert_equal 6, m['value']
      assert_equal 'Google Desktop', m['agent_name']
      assert_equal 'misc', m['agent_category']
      assert_equal 'UNKNOWN', m['agent_os']

      # 'agent' => 'msnbot/1.1 (+http://search.msn.com/msnbot.htm)'
      m = filtered[7][2]
      assert_equal 7, m['value']
      assert_equal 'msnbot', m['agent_name']
      assert_equal 'crawler', m['agent_category']
      assert_equal 'UNKNOWN', m['agent_os']
    end

  end
end