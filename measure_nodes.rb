#!/usr/local/bin/ruby

#Usage: ruby measure_nodes.rb <# of times to request each resource> <URI filename>

#Example: ruby measure_nodes.rb 2 test_uri.txt

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

def findRemoteHostname(resource)
    resource.strip.match(/http:\/\/([a-z0-9.]+[a-z0-9])\//)
    fqdn = $1
    if(fqdn.nil?) #assume resource is an ip address...
        host_out = %x(host #{resource.strip})
        host_out.match(/pointer (.*$)/)
        fqdn = $1
    end
    return fqdn.strip
end

def findRemoteIp(resource)
    hostname = findRemoteHostname(resource)
    nslookup_out = %x(nslookup #{hostname})
    nslookup_out.match(/Address: (\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})/)
    ip = $1
    return ip.strip
end

def measurePingRtt(resource)
    hostname = findRemoteHostname(resource)
    ping_out = %x(ping -c1 #{hostname})
    ping_out.match(/time=(\w+.?\w+) ms/)
    rtt = $1
    if(!rtt.nil?)
        return rtt.strip
    else
        raise "UNKNOWN RTT INDICATOR:\n#{ping_out}"
    end
end

def measureWgetBdwth(resource)
    tera = 1000000000
    giga = 1000000
    mega = 1000
    kilo = 1 
    wget_out = %x(wget #{resource.strip} -O /dev/null 2>&1)
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

if(ARGV.length != 2)
    puts "THIS SCRIPT REQUIRES TWO ARGUMENTS\n#Usage: ruby resource_bdwdth_tester.rb <# of times to request each resource> <URI filename>"
    exit
end

request_count = Integer(ARGV[0])
uri_filename = ARGV[1]

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
