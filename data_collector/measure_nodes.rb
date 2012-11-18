#!/usr/local/bin/ruby

require 'optparse'
require 'timeout'

options = {}
optparse = OptionParser.new { |opts|
    opts.banner = <<-EOS
Usage: ruby measure_nodes.rb [-a alternate src count]  [-t ingress | egress] -r uri request count -f /path/to/uri/list/file [-o /path/to/out/file]

Example 1: ruby measure_nodes.rb -a 1 -t egress -r 2 -f ../test/test_uri.txt
Example 2: ruby measure_nodes.rb -r 1 -f ../test/espn_sample_uri_list.txt -o ../test/out.csv

Output Format:
local_node_name,local_ip_addr,local_mac_addr,local_geoip_info,remote_node_name,remote_ip_addr,remote_mac_addr,remote_geoip_info,timestamp,alt_src_type,syn_count,bandwidth,rtt,uri

Note: This program requires the hping3 tool (http://www.hping.org/) be installed and runnable by the user in order to use the alternate source ip feature.
    EOS
    opts.on('-h','--help','Display this screen') {
        puts opts
        exit
    }
    options[:alt_src_count] = 0
    opts.on('-a','--alt_count N','Alternate Source Count N') { |n|
        options[:alt_src_count] = Integer(n)
    }
    options[:alt_src_type] = :none
    opts.on('-t','--type T',[:ingress,:egress],'Alternate Source Type T') { |t|
        options[:alt_src_type] = t
    }
    options[:uri_req_count] = 1
    opts.on('-r','--req_count C','URI Request Count C') { |c|
        options[:uri_req_count] = Integer(c)
    }
    options[:uri_file_path] = nil
    opts.on('-f','--file FILE','URI File Path FILE') { |file|
        options[:uri_file_path] = file
    }
    options[:out_file_path] = "node_measurements.csv"
    opts.on('-o','--out FILE','Output File Path FILE') { |file|
        options[:out_file_path] = file
    }
}

optparse.parse!
if (options[:uri_file_path].nil?)
    raise OptionParser::MissingArgument,"URI File Path = #{options[:uri_file_path]}"
elsif (options[:alt_src_type] == :none && options[:alt_src_count] > 0)
    raise OptionParser::MissingArgument,"Alternate Source Count = #{options[:alt_src_count]} but Alternate Source Type = #{options[:alt_src_type]}"
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

def findLocalHostname()
    hostname = %x(hostname -f)
    return hostname.strip
end

def findLocalIp()
    ip_out = %x(curl -s http://automation.whatismyip.com/n09230945.asp)
    if(ip_out.match(/^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$/))
        ip = $1
        return ip.strip
    else
        raise "UNRECOGNIZED IP ADDRESS:\n#{ip}"
    end
end

def findLocalMac()
    en_out = %x(/sbin/ifconfig -a)
    mac = nil
    if(en_out.match(/ether (\w{2}:\w{2}:\w{2}:\w{2}:\w{2}:\w{2})/))
        mac = $1
    elsif(en_out.match(/HWaddr (\w{2}:\w{2}:\w{2}:\w{2}:\w{2}:\w{2})/))
        mac = $1
    else
        raise "UNRECOGNIZED MAC ADDRESS:\n#{en_out}"
    end
    return mac.strip
end

def findRemoteHostname(uri)
    uri.strip.match(/http:\/\/([a-zA-Z0-9.-]+[a-z0-9])(\/|$)/)
    fqdn = $1
    if(fqdn.nil?) #assume uri is an ip address...
        host_out = %x(host #{uri.strip})
        host_out.match(/pointer (.*$)/)
        fqdn = $1
        if(fqdn.nil?)
            puts "COULD NOT FIND FQDN FOR URI '#{uri.strip}':"
            puts "#{host_out}"
        end
    end
    return fqdn.strip
end

def findRemoteIp(uri)
    hostname = findRemoteHostname(uri)
    nslookup_out = %x(nslookup #{hostname})
    nslookup_out.match(/Address: (\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})/)
    ip = $1
    return ip.strip
end

def sendAltSrcSyns(syn_count,uri,alt_src_type)
    alt_src_ip = nil
    hostname = findRemoteHostname(uri)
    ip = findRemoteIp(uri)
    ip_ary = ip.split(/\./)
    if(alt_src_type == :egress)
        #assume CIDR block with 24 bit prefix (a.b.c.d/24)
        alt_src_ip = "#{ip_ary[0]}.#{ip_ary[1]}.#{ip_ary[2]}.#{rand(255)}"
    elsif(alt_src_type == :ingress)
        alt_src_ip = "#{rand(ip_ary[0])}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    else
        alt_src_ip = nil
    end
    if(!alt_src_ip.nil? && syn_count > 0)
        %x(sudo hping3 -S -a #{alt_src_ip} #{hostname} -c #{syn_count})
    end
end

def measureWgetBdwth(uri)
    puts "MEASURING BANDWIDTH WITH WGET..."
    tera = 1000000000
    giga = 1000000
    mega = 1000
    kilo = 1 
    puts "ORIGINAL URI: #{uri}"
    uri.strip.match(/(http:\/\/[a-zA-Z0-9\.\-]+[a-z0-9][\/]*[a-zA-Z0-9\-\_\.\~\/]*)/)
    uri = $1
    puts "TRIMMED URI: '#{uri.strip}'"
    wget_out = %x(wget #{uri.strip} -O /dev/null 2>&1)
    puts "WGET OUT: #{wget_out}"
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
    end
    return ret #in KB/s
end

def measurePingRtt(uri)
    hostname = findRemoteHostname(uri)
    ping_out = %x(ping -c1 #{hostname})
    ping_out.match(/time=(\w+.?\w+) ms/)
    rtt = $1
    if(!rtt.nil?)
        return rtt.strip
    else
        raise "UNKNOWN RTT INDICATOR:\n#{ping_out}"
    end
end

syn_count = options[:alt_src_count]
alt_src_type = options[:alt_src_type]
request_count = options[:uri_req_count]
uri_filename = options[:uri_file_path]

puts "Using alternate source #{syn_count} times prior to each bandwidth measurement..."
puts "Alternate source test type #{alt_src_type}..."
puts "Requesting each URI #{request_count} time(s)..."
puts "Accessing URI's listed in #{uri_filename}..."
puts

UNSET = "<unavailable>"
ERROR = "<error>"
SEC = 1
MIN = 60 * SEC
MAX_T = 3 * MIN

local_node_name = UNSET
local_ip_addr = UNSET
local_mac_addr = UNSET
local_geoip_info = UNSET

table = Array.new
out_file_handle = File.open(options[:out_file_path],'w')

print "working..."
uri_file_handle = File.open(uri_filename,'r')
while (uri = uri_file_handle.gets) 
    request_count.times {
        print "."
        STDOUT.flush
        row = DataRow.new

        puts "FILLING CLIENT VALS..."
        if(local_node_name == UNSET)
            local_node_name = findLocalHostname()
        end
        row.local_node_name = local_node_name
        if(local_ip_addr == UNSET)
            begin
                Timeout::timeout(MAX_T) {
                    local_ip_addr = findLocalIp()
                }
            rescue
                puts "\nException Raised: #{$!}"
                local_ip_addr = ERROR
            rescue Timeout::Error
                puts "\nTimeout Error: #{$!}"
            end
        end
        row.local_ip_addr = local_ip_addr
        if(local_mac_addr == UNSET)
            begin
                Timeout::timeout(MAX_T) {
                    local_mac_addr = findLocalMac()
                }
            rescue
                puts "\nException Raised: #{$!}"
                local_mac_addr = ERROR
            rescue Timeout::Error
                puts "\nTimeout Error: #{$!}"
            end
        end
        row.local_mac_addr = local_mac_addr
        if(local_geoip_info == UNSET)
            #TODO: set geoip info here?
        end
        row.local_geoip_info = local_geoip_info

        puts "FILLING SERVER VALS..."
        begin
            Timeout::timeout(MAX_T) {
                row.remote_node_name = findRemoteHostname(uri)
            }
        rescue
            puts "\nException Raised: #{$!}"
            row.remote_node_name = ERROR
        rescue Timeout::Error
            puts "\nTimeout Error: #{$!}"
        end
        begin
            Timeout::timeout(MAX_T) {
                row.remote_ip_addr = findRemoteIp(uri)
            }
        rescue
            puts "\nException Raised: #{$!}"
            row.remote_ip_addr = ERROR
        rescue Timeout::Error
            puts "\nTimeout Error: #{$!}"
        end
        row.remote_mac_addr = UNSET
        row.remote_geoip_info = UNSET

        puts "FILLING URI VALS..."
        row.timestamp = Time.now
        row.alt_src_type = alt_src_type
        row.syn_count = syn_count
        begin
            Timeout::timeout(MAX_T) {
                sendAltSrcSyns(syn_count,uri,alt_src_type)
            }
        rescue
            puts "\nException Raised: #{$!}"
            puts "Ignoring..."
        rescue Timeout::Error
            puts "\nTimeout Error: #{$!}"
        end
        begin
            Timeout::timeout(MAX_T) {
                row.bandwidth = measureWgetBdwth(uri)
            }
        rescue
            puts "\nException Raised: #{$!}"
            row.bandwidth = ERROR
        rescue Timeout::Error
            puts "\nTimeout Error: #{$!}"
        end
        begin
            Timeout::timeout(MAX_T) {
                row.rtt = measurePingRtt(uri)
            }
        rescue
            puts "\nException Raised: #{$!}"
            row.rtt = ERROR
        rescue Timeout::Error
            puts "\nTimeout Error: #{$!}"
        end

        puts "CREATING DATA ROW..."
        row.uri = uri.strip
        table << row
    }
end
puts
puts "WRITING #{table.size} ROWS TO CSV..."
table.each { |row|
    out_file_handle.puts row.to_s
}
uri_file_handle.close
out_file_handle.close
puts "done."
