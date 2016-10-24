class Fluent::SLFParserFilter < Fluent::Filter
  Fluent::Plugin.register_filter('slfparser', self)
  # // TODO add config here

  def initialize
    super
  end

  def configure(conf)
    super
  end

  def filter_stream(tag, es)
    new_es = Fluent::MultiEventStream.new

    es.each do |time, record|
      #puts "Time: " + time.to_s
      #puts "Record: " + record.to_s

      record['time'] = time

      unless record['log'].nil?

        if match = record['log'].match(/^\[(.+)\] (\w+) ([a-z.]+) .*/i)
          thread, level, logger = match.captures
          record = record.merge({'java-thread' => thread, 'severity' => level, 'java-logger' => logger})
        end

      end

      unless record['container_name'].nil?
        # append tournament based on container_name
        if (record['container_name'].include? "bl-backend")
          record = record.merge({
                                    'tournament' => 'bundesliga',
                                    'type' => 'java-backend'
                                })
        end
        if (record['container_name'].include? "bl2-backend")
          record = record.merge({
                                    'tournament' => 'liga2',
                                    'type' => 'java-backend'
                                })
        end
        if (record['container_name'].include? "l3-backend")
          record = record.merge({
                                    'tournament' => 'liga3',
                                    'type' => 'java-backend'
                                })
        end
        if (record['container_name'].include? "tt-backend")
          record = record.merge({
                                    'tournament' => 'tt',
                                    'type' => 'java-backend'
                                })
        end
        if (record['container_name'].include? "twitter-module")
          record = record.merge({
                                    'type' => 'java-twitter'
                                })
        end
        if (record['container_name'].include? "pub-sub-module")
          record = record.merge({
                                    'type' => 'java-pubsub'
                                })
        end
        if (record['container_name'].include? "k8s_router")
          record = record.merge({
                                    'type' => 'java-router'
                                })

          # additional http access log parsing
          if match = record['log'].match(/(.*?)-(.*?)- \[(.*?)\] "(GET|POST|PUT|DELETE|OPTIONS|HEAD|TRACE) (.*?) (HTTP)\/(.*?)" (\d*) (\d*) "(.*?)" "(.*?)" "(.*?)"/i)

            # puts match.captures.inspect
            status = match.captures[7]
            method = match.captures[3]
            request = match.captures[4]
            bytes = match.captures[8]
            userAgent = match.captures[10]

            severity = 'INFO'

            if (status.to_i >= 500)
              severity = 'WARNING'
            end

            if (userAgent == 'GoogleStackdriverMonitoring-UptimeChecks(https://cloud.google.com/monitoring)')
              severity = 'DEBUG'
            end

            record = record.merge({'http_status' => status,
                                   'http_method' => method,
                                   'http_request' => request,
                                   'http_bytes' => bytes,
                                   'http_user_agent' => userAgent,
                                   'severity' => severity})

          end
        end
      end

      # check for garbage collection
      if (record['source'] == 'stdout' && (record['type'] == 'java-backend' || record['type'] == 'java-twitter' || record['type'] == 'java-pubsub'))
        record = record.merge({'java-logger' => 'GarbageCollection', 'severity' => 'DEBUG'})
      end

      new_es.add(time, record.dup)
    end
    new_es
  end
end if defined?(Fluent::Filter)