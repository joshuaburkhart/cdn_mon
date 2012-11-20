#!/usr/bin/ruby

ARGV.each { |collected_data_file|
    %x(ruby /Users/joshuaburkhart/Software_Projects/CIS_630/cdn_mon/data_cleaner/geoip_resolver.rb -g /Users/joshuaburkhart/Software_Projects/CIS_630/cdn_mon/data_cleaner/GeoLiteCity.dat -f /Users/joshuaburkhart/Software_Projects/CIS_630/cdn_mon/remote_output/putative_valid_output/#{collected_data_file} -o #{collected_data_file}.geoip.csv)
}
