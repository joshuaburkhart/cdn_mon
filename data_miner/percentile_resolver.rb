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
    options[:reverse] = false
    opts.on('-r','--reverse','Reverse specified percentile to upper threshold'){
        options[:reverse] = true
    }
}
optparse.parse!
if(options[:infile].nil?)
    raise OptionParser::MissingArgument,"Metrics File Path = #{options[:infile]}"
end

puts "Percentile:  #{options[:percentile]}"
puts "Input File:  #{options[:infile]}"
puts "Output File: #{options[:outfile]}"
puts "Reverse Order: #{options[:reverse]}"

ERROR = "<error>"
NAN = "NaN"
out_handle = File.open(options[:outfile],'w')
in_handle = File.new(options[:infile])
puts
orig_files = in_handle.gets #on first line
#puts "ORIGINAL: #{orig_files}"
geo_info = in_handle.gets #on second line
#puts "GEO INFO: #{geo_info}"
geo_ary = geo_info.split(',')
nodes = Array.new
(0..geo_ary.length - 1).each { |i|
    nodes[i] = Array.new
    #puts "NODE #{i} HAS GEO INFO: #{geo_ary[i]}"
    nodes[i][0] = geo_ary[i].to_s.strip
    #puts "ADDING TO NODES>>> NOW: #{nodes.inspect}"
}

while line = in_handle.gets
    metrics_list = line.split(',')
    #puts "METRICS LIST 0: #{metrics_list[0]}"
    #puts "METRICS LIST 1: #{metrics_list[1]}"
    #puts "METRICS LIST 2: #{metrics_list[2]}"
    #puts "METRICS LIST LENGTH #{metrics_list.size}"
    (1..metrics_list.length - 1).each { |i|
        nidx = i - 1
        if(nodes.nil?)
            puts "\nERROR: NODES NIL"
        elsif(nodes[nidx].nil?)
            puts "\nERROR: NODES[NIDX] NIL"
            puts "NODES: #{nodes.inspect}"
        end
        current = nodes[nidx][1]
        metric = metrics_list[i].strip
        if(metric != ERROR && metric != NAN)
            metric = Float(metric)
            if(!current.nil? && current != ERROR)
                nodes[nidx][1] = (current + metric)
            else
                nodes[nidx][1] = metric
            end
        elsif(current == ERROR)
            nodes[nidx][1] = ERROR
        else
            #leave nodes[nidx][1] unmodified
        end
        #puts "ADDING #{metric} TO NODE[#{nidx}]: #{nodes[nidx][0]}"
    }
end

if(options[:reverse] == true)
    puts "SORTING IN REVERSE (LARGE -> SMALL)"
    nodes.sort! { |i,j|
        j[1] <=> i[1]
    }
else
    puts "SORTING NORMAL (SMALL -> LARGE)"
    nodes.sort! { |i,j|
        i[1] <=> j[1]
    }
end
puts nodes.inspect

percentage = 1 - (options[:percentile] / 100.0)
idx_threshold = percentage * nodes.length

valid_idx = 0
while valid_idx < idx_threshold
    out_handle.puts(nodes[valid_idx][0])
    valid_idx += 1
end

out_handle.close
in_handle.close
