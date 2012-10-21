#!/usr/local/bin/ruby

#Usage: ruby spoof_response_tester.rb <http://a.sample/resource/to/downlo.ad> <the IP address to spoof>

#Example: ruby spoof_response_tester.rb http://passets-ec.pinterest.com/js/bundle_pin_cb9c367b.js 15.193.176.227

if(ARGV.length != 2)
	puts "THIS SCRIPT REQUIRES TWO ARGUMENTS\n#Usage: ruby spoof_response_tester.rb <http://a.sample/resource/to/downlo.ad> <the IP address to spoof>\n#Example: ruby spoof_response_tester.rb http://passets-ec.pinterest.com/js/bundle_pin_cb9c367b.js 15.193.176.227"
	exit
end

resource = ARGV[0]
spoofed_ip = ARGV[1]
resource.match(/http:\/\/([a-z0-9.]+[a-z0-9])\//)
target = $1
SPOOF_TRIES = 1
REAL_TRIES = 5

#use hping3 to spoof single tcp SYN
hping3_spoof_out = %x(sudo hping3 -S -a #{spoofed_ip} #{target} -c #{SPOOF_TRIES})

#parse RTTs
rtts = Array.new
REAL_TRIES.times {
	hping3_real_out = %x(sudo hping3 #{target} -c 1 2>&1)
	if(hping3_real_out.match(/rtt=(\d+\.?\d*) ms/))
		rtts << Float($1)
	else
		puts "UNABLE TO REACH HOST"
		exit
	end
}

#use wget to download a large resource several times
bdwdth = Array.new
TERA = 1000000000
GIGA = 1000000
MEGA = 1000
KILO = 1
REAL_TRIES.times {
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
puts "min: #{rtts.sort.first}"
puts "max: #{rtts.sort.last}"
puts "avg: #{rtts.reduce(:+) / rtts.count}"
puts
puts "Observed Bandwidth (KB/s):"
puts bdwdth
puts "min: #{bdwdth.sort.first}"
puts "max: #{bdwdth.sort.last}"
puts "avg: #{bdwdth.reduce(:+) / bdwdth.count}"

