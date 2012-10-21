#!/usr/local/bin/ruby

#Usage: ruby spoof_response_tester.rb <http://a.sample/resource/to/downlo.ad> <the IP address to spoof>

#Example: ruby spoof_response_tester.rb http://passets-ec.pinterest.com/js/bundle_pin_cb9c367b.js 15.193.176.227

resource = ARGV[0]
spoofed_ip = ARGV[1]
resource.match(/http:\/\/([a-z0-9.]+[a-z0-9])\//)
target = $1

#use hping3 to spoof single tcp SYN
hping3_spoof_out = %x(sudo hping3 -S -a #{spoofed_ip} #{target} -c 1)

#use hping3 to send several legitimate tcp packets
hping3_real_out = %x(sudo hping3 #{target} -c 5)

#parse RTT's
hping3_real_out.match(/ (\d+.\d+)\/\d+\.\d+\/\d+\.\d+ ms/)
rtt_min = $1

hping3_real_out.match(/ \d+.\d+\/(\d+\.\d+)\/\d+\.\d+ ms/)
rtt_avg = $1

hping3_real_out.match(/ \d+.\d+\/\d+\.\d+\/(\d+\.\d+) ms/)
rtt_max = $1

hping3_real_out.match(/rtt=(\d+\.\d+) ms/)
rtts = Array.new
rtts << $1
rtts << $2
rtts << $3
rtts << $4
rtts << $5

#use wget to download a large resource several times
bdwdth = Array.new
TERA = 1000000000
GIGA = 1000000
MEGA = 1000
KILO = 1
5.times {
	wget_out = %x(wget #{resource} 2>&1)
	wget_out.match(/\((\d+.?\d* [A-Z]B\/s)\)/)
	speed = $1
	if(speed.match(/(\d+.?\d*) TB\/s/))
		bdwdth << Float($1) * TERA
	elsif(speed.match(/(\d+.?\d*) GB\/s/))
		bdwdth << Float($1) * GIGA
	elsif(speed.match(/(\d+.?\d*) MB\/s/))
		bdwdth << Float($1) * MEGA
	elsif(speed.match(/(\d+.?\d*) KB\/s/))
		bdwdth << Float($1) * KILO
	else
		puts "UNKOWN BANDWIDTH INDICATOR:\n#{wget_out}"
		exit
	end
}

#print results
puts "SPOOFED IP RESPONSE"
puts "==================="
puts
puts "Observed RTT's (ms):"
puts rtts
puts "min: #{rtt_min}"
puts "max: #{rtt_max}"
puts "avg: #{rtt_avg}"
puts
puts "Observed Bandwidth (KB/s):"
puts bdwdth
puts "min: #{bdwdth.sort.first}"
puts "max: #{bdwdth.sort.last}"
puts "avg: #{bdwdth.reduce(:+) / bdwdth.count}"
