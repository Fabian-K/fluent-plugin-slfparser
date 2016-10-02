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
        if (record['container_name'].include? "k8s_router")
          record = record.merge({
                                    'type' => 'java-router'
                                })

          # additional http access log parsing
          if match = record['log'].match(/ ([0-9]{3}) /i)
            status = match.captures[0]

            severity = 'INFO'

            if (status.to_i >= 500)
              severity = 'WARNING'
            end

            record = record.merge({'status' => status,
                                   'severity' => severity})


          end
        end
      end

      # check for garbage collection
      if (record['source'] == 'stdout' && record['type'] == 'java-backend')
        record = record.merge({'java-logger' => 'GarbageCollection', 'severity' => 'DEBUG'})
      end

      new_es.add(time, record.dup)
    end
    new_es
  end
end if defined?(Fluent::Filter)