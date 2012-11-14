#!/usr/local/bin/ruby

require 'optparse'

options = {}
optparse = OptionParser.new { |opts|
    opts.banner = <<-EOS
Usage: ruby percentile_resolver.rb -p <percentile limit> -f <list of common metrics> -o <output file>

Example: ruby percentile_resolver.rb -p 75 -f ../test/average_rtts.csv -o ../test/top75rtts.csv

Output Format:
geoip 1
.
.
geoip N
    EOS
    opts.on('-h','--help','Display this screen'){
        puts opts
        exit
    }
    options[:percentile] = 50
    opts.on('-p','--percentile PERCENTILE','Percentile lower threshold PERCENTILE'){ |percentile|
        options[:percentile] = Integer(percentile)
    }
    options[:infile] = nil
    opts.on('-f','--file FILE','File Path With Metrics FILE'){ |file|
        options[:infile] = file
        options[:outfile] = "#{file}_top#{options[:percentile]}percentile"
    }
    opts.on('-o','--out FILE','Output File Path FILE'){ |file|
        options[:outfile] = file
    }
}
optparse.parse!
if(options[:infile].nil?)
    raise OptionParser::MissingArgument,"Metrics File Path = #{options[:infile]}"
end

puts "Percentile:  #{options[:percentile]}"
puts "Input File:  #{options[:infile]}"
puts "Output File: #{options[:outfile]}"

out_handle = File.open(options[:outfile],'w')
in_handle = File.new(options[:infile])

orig_files = in_handle.gets #on first line
puts orig_files
geo_info = in_handle.gets #on second line
puts geo_info
geo_ary = geo_info.split(',')
nodes = Array.new
(0..geo_ary.length - 1).each { |i|
    nodes[i] = Array.new
puts "TESTING----------"    
puts geo_ary[i]
puts "TESTING-----------"
    nodes[i][0] = geo_ary[i]
}

while line = in_handle.gets
    metrics_list = line.split
    (1..metrics_list.length - 1).each { |i|
        nodes[i][1] += metrics_list[i]
    }
end

nodes.sort! { |i,j|
    i[1] <=> j[1]
}

percentage = 1 - (options[:percentile] / 100.0)
idx_threshold = percentage * nodes.length

valid_idx = 0
puts "TESTING------------------"
puts nodes.inspect
puts nodes[0].inspect
puts nodes[0]
puts nodes[0][0]
puts "TESTING=--=---------------"
while valid_idx < idx_threshold
    out_handle.puts(nodes[valid_idx][0])
    valid_idx += 1
end

out_handle.close
in_handle.close
