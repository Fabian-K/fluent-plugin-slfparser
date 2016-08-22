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

      # append tournament based on container_name
      if (record['container_name'].include? "bl-backend")
        record = record.merge({
                                  'tournament' => 'bundesliga'
                              })
      end
      if (record['container_name'].include? "bl2-backend")
        record = record.merge({
                                  'tournament' => 'liga2'
                              })
      end
      if (record['container_name'].include? "l3-backend")
        record = record.merge({
                                  'tournament' => 'liga3'
                              })
      end

      new_es.add(time, record.dup)
    end
    new_es
  end
end if defined?(Fluent::Filter)