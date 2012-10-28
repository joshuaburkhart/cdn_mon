#!/usr/local/bin/ruby

h = <<-EOS
#Usage: ruby measure_nodes.rb <alternate src count> <alternate src type (ingress / egress)> <uri request count> </path/to/uri/list/file>

#Example: ruby measure_nodes.rb 0 e 2 test_uri.txt

#Note: This program requires the hping3 tool (http://www.hping.org/) be installed and runnable by the user in order to use the alternate source ip feature.
EOS

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
    ip = %x(curl -s http://automation.whatismyip.com/n09230945.asp)
    return ip.strip
end

def findLocalMac()
    en_out = %x(ifconfig -a)
    en_out.match(/ether (\w{2}:\w{2}:\w{2}:\w{2})|HWaddr (\w{2}:\w{2}:\w{2}:\w{2})/)
    mac = $1
    return mac.strip
end

def findRemoteHostname(uri)
    uri.strip.match(/http:\/\/([a-z0-9.]+[a-z0-9])\//)
    fqdn = $1
    if(fqdn.nil?) #assume uri is an ip address...
        host_out = %x(host #{uri.strip})
        host_out.match(/pointer (.*$)/)
        fqdn = $1
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

def sendAltSrcSyns(alt_src_count,uri,alt_src_type)
    alt_src_ip = nil
    hostname = findRemoteHostname(uri)
    ip = findRemoteIp(uri)
    ip_ary = ip.split(/\./)
    if(alt_src_type == "i")
        #assume CIDR block with 24 bit prefix (a.b.c.d/24)
        alt_src_ip = "#{ip_ary[0]}.#{ip_ary[1]}.#{ip_ary[2]}.#{rand(255)}"
    elsif(alt_src_type == "e")
        alt_src_ip = "#{rand(ip_ary[0])}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    else
        alt_src_ip = nil
    end
    if(alt_src_count > 0 && !alt_src_ip.nil?)
        %x(sudo hping3 -S -a #{alt_src_ip} #{hostname} -c #{alt_src_count})
    end
end

def measureWgetBdwth(uri)
    tera = 1000000000
    giga = 1000000
    mega = 1000
    kilo = 1 
    wget_out = %x(wget #{uri.strip} -O /dev/null 2>&1)
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

if(ARGV.length != 4)
    puts "THIS SCRIPT REQUIRES 4 ARGUMENTS"
    puts h
    exit
end

alt_src_count = Integer(ARGV[0])
alt_src_type = ARGV[1].to_s[0,1]
request_count = Integer(ARGV[2])
uri_filename = ARGV[3]

puts "Using alternate source #{alt_src_count} times prior to each bandwidth measurement..."
puts "Alternate source test type #{alt_src_type}..."
puts "Requesting each URI #{request_count} time(s)..."
puts "Accessing URI's listed in #{uri_filename}..."
puts

UNSET="<unavailable>"
ERROR="<error>"

table = Array.new
out_file_handle = File.open("node_measurements.csv",'a')

print "working..."
uri_file_handle = File.open(uri_filename,'r')
while (uri = uri_file_handle.gets) 
    request_count.times {
        print "."
        STDOUT.flush
        row = DataRow.new

        row.local_node_name = findLocalHostname()
        row.local_ip_addr = findLocalIp()
        row.local_mac_addr = findLocalMac()
        row.local_geoip_info = UNSET

        row.remote_node_name = findRemoteHostname(uri)
        row.remote_ip_addr = findRemoteIp(uri)
        row.remote_mac_addr = UNSET
        row.remote_geoip_info = UNSET

        row.timestamp = Time.now
        sendAltSrcSyns(alt_src_count,uri,alt_src_type)
        begin
            row.bandwidth = measureWgetBdwth(uri)
        rescue
            puts "\nException Raised: #{$!}"
            row.bandwidth = ERROR
        end
        begin
            row.rtt = measurePingRtt(uri)
        rescue
            puts "\nException Raised: #{$!}"
            row.rtt = ERROR
        end
        row.uri = uri.strip
        table << row
    }
end
puts
table.each { |row|
    out_file_handle.puts row.to_s
}
uri_file_handle.close
out_file_handle.close
puts "done."
