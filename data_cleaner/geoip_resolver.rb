#!/usr/local/bin/ruby

require 'rubygems'
require 'geoip'
require 'optparse'

options = {}
optparse = OptionParser.new { |opts|
    opts.banner = <<-EOS
Usage: ruby geoip_resolver.rb -f /path/to/data/file [-o /path/to/out/file]

Example 1: ruby geoip_resolver.rb -f ../test/out.csv
Example 2: ruby geoip_resolver.rb -f ../test/out.csv -o ../test/out.geoip.csv

Output Format:
local_node_name,local_ip_addr,local_mac_addr,local_geoip_info,remote_node_name,remote_ip_addr,remote_mac_addr,remote_geoip_info,timestamp,alt_src_type,syn_count,bandwidth,rtt,uri
    EOS
    opts.on('-h','--help','Display this screen') {
        puts opts
        exit
    }
    options[:data_file_path] = nil
    opts.on('-f','--file FILE','Data File Path FILE') { |file|
        options[:data_file_path] = file
    }
    options[:out_file_path] = "#{options[:data_file_path]}.geoip.csv"
    opts.on('-o','--out FILE','Output File Path FILE') { |file|
        options[:out_file_path] = file
    }
    options[:geo_ip_file_path] = "GeoLiteCity.dat"
    opts.on('-g','--geoip FILE','Geo IP File Path FILE') { |file|
        options[:geo_ip_file_path] = file
    }
}

optparse.parse!
if (options[:data_file_path].nil?)
    raise OptionParser::MissingArgument,"URI File Path = #{options[:data_file_path]}"
end

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
    attr_accessor :alt_src_type
    attr_accessor :syn_count
    attr_accessor :bandwidth
    attr_accessor :rtt
    attr_accessor :uri

    def to_s
        return\
            "#{@local_node_name},"\
            "#{@local_ip_addr},"\
            "#{@local_mac_addr},"\
            "#{@local_geoip_info},"\
            \
            "#{@remote_node_name},"\
            "#{@remote_ip_addr},"\
            "#{@remote_mac_addr},"\
            "#{@remote_geoip_info},"\
            \
            "#{@timestamp},"\
            "#{@alt_src_type},"\
            "#{@syn_count},"\
            "#{@bandwidth},"\
            "#{@rtt},"\
            "#{@uri}"
    end
end

def getGeoIpInfo(geoip,addr)
    lat = "<unavailable>"
    long = "<unavailable>"
    if(addr.match(/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/))
       city = geoip.city(addr)
       lat = city.latitude
       long = city.longitude
    end
    return "(#{lat},#{long})"
end

puts "Reading from '#{options[:data_file_path]}'..."
puts "Outputting to '#{options[:out_file_path]}'..."
puts

UNSET="<unavailable>"
ERROR="<error>"

table = Array.new
out_file_handle = File.open(options[:out_file_path],'w')
data_filename = options[:data_file_path]
geoip = GeoIP.new(options[:geo_ip_file_path])

print "working..."
data_file_handle = File.open(data_filename,'r')
while (dirty_row = data_file_handle.gets) 
    print "."
    STDOUT.flush
    clean_row = DataRow.new

    clean_row.local_node_name   = dirty_row.split(',')[0]
    clean_row.local_ip_addr     = dirty_row.split(',')[1]
    clean_row.local_mac_addr    = dirty_row.split(',')[2] 
    clean_row.local_geoip_info  = getGeoIpInfo(geoip,clean_row.local_ip_addr)

    clean_row.remote_node_name  = dirty_row.split(',')[4]
    clean_row.remote_ip_addr    = dirty_row.split(',')[5]
    clean_row.remote_mac_addr   = dirty_row.split(',')[6]
    clean_row.remote_geoip_info = getGeoIpInfo(geoip,clean_row.remote_ip_addr)

    clean_row.timestamp         = dirty_row.split(',')[8]
    clean_row.alt_src_type      = dirty_row.split(',')[9]
    clean_row.syn_count         = dirty_row.split(',')[10]
    clean_row.bandwidth         = dirty_row.split(',')[11]
    clean_row.rtt               = dirty_row.split(',')[12]
    clean_row.uri               = dirty_row.split(',')[13]

    table << clean_row
end
puts
puts "WRITING #{table.size} ROWS TO CSV..."
table.each { |row|
    out_file_handle.puts row.to_s
}
data_file_handle.close
out_file_handle.close
puts "done."
