#!/usr/local/bin/ruby

#Usage: ruby resource_bdwdth_tester.rb <# of times to request each resource> <URI>
#TODO: change <URI> above to a filename containing a list of URI's

#Example:

class DataRow
    attr_accessor :local_node_name
    attr_accessor :local_ip_addr
    attr_accessor :local_mac_addr
    attr_accessor :local_geoip_info

    attr_accessor :remote_node_name
    attr_accessor :remote_ip_addr
    attr_accessor :remote_mac_addr
    attr_accessor :remote_geoip_info

    attr_accessor :timestamp
    attr_accessor :bandwidth
    attr_accessor :rtt
    attr_accessor :uri

    def to_s
        print "#{@local_node_name},"
        print "#{@local_ip_addr},"
        print "#{@local_mac_addr},"
        print "#{@local_geoip_info},"

        print "#{@remote_node_name},"
        print "#{@remote_ip_addr},"
        print "#{@remote_mac_addr},"
        print "#{@remote_geoip_info},"

        print "#{@timestamp},"
        print "#{@bandwidth},"
        print "#{@rtt},"
        print "#{@uri}\n"
    end
end

def measureWgetBdwth(resource)
    tera = 1000000000
    giga = 1000000
    mega = 1000
    kilo = 1 
    wget_out = %x(wget #{resource} 2>&1)
    wget_out.match(/\((\d+.?\d* [A-Z]B\/s)\)/)
    speed = $1
    if(speed.match(/(\d+.?\d*) TB\/s/))
        ret = "#{Float($1) * tera}"
    elsif(speed.match(/(\d+.?\d*) GB\/s/))
        ret = "#{Float($1) * giga}"
    elsif(speed.match(/(\d+.?\d*) MB\/s/))
        ret = "#{Float($1) * mega}"
    elsif(speed.match(/(\d+.?\d*) KB\/s/))
        ret = "#{Float($1) * kilo}"
    else
        raise "UNKOWN BANDWIDTH INDICATOR:\n#{wget_out}"
        exit
    end
    return "#{ret} KB/s"
end

if(ARGV.length != 2)
    puts "THIS SCRIPT REQUIRES TWO ARGUMENTS\n#Usage: ruby resource_bdwdth_tester.rb <# of times to request each resource> <URI>"
    exit
end

request_count = Integer(ARGV[0])
uri = ARGV[1]
UNSET="empty"
ERROR="unavailable"

table = Array.new

print "working..."
request_count.times {
    print "."
    STDOUT.flush
    row = DataRow.new

    row.local_node_name = UNSET
    row.local_ip_addr = UNSET
    row.local_mac_addr = UNSET
    row.local_geoip_info = UNSET

    row.remote_node_name = UNSET
    row.remote_ip_addr = UNSET
    row.remote_mac_addr = UNSET
    row.remote_geoip_info = UNSET

    row.timestamp = UNSET
    begin
        row.bandwidth = measureWgetBdwth(uri)
    rescue
        puts "Exception Raised: #{$!}"
        row.bandwidth = ERROR
    end
    row.rtt = UNSET
    row.uri = UNSET
    table << row
}
puts
table.each { |row|
    row.to_s
}
