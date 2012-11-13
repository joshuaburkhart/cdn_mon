#!/usr/local/bin/ruby

require 'optparse'

options = {}
optparse = OptionParser.new { |opts|
    opts.banner = <<-EOS
Usage: ruby raw_stats.rb -l /cleaned/csv/1 [/cleaned/csv/2 ...] [-o /out/csv]

Example 1: ruby raw_stats.rb -l ../test/out.geoip.csv
Example 2: ruby raw_stats.rb -l ../test/out.geoip.csv,../test2/out.geoip.csv -o ../test/average_rtts.csv

Output Format:
<first row has infile names>
<second row has infile node geo info>
uri,RTT avg 1,RTT avg 2,RTT avg N
    EOS
    opts.on('-h','--help','Display this screen') {
        puts opts
        exit
    }
    options[:data_files] = nil
    opts.on('-l','--list a,b,c',Array,"Data File Paths - 'list' CSVs") { |l|
        options[:data_files] = l
    }
    options[:out_file_path] = "avg_rtt_stats.csv"
    opts.on('-o','--out FILE','Output File Path FILE') { |file|
        options[:out_file_path] = file
    }
}

optparse.parse!
if (options[:data_files].nil?)
    raise OptionParser::MissingArgument,"URI File Path = #{options[:data_files]}"
end

def writeBufferVals(file_handle,uri,buffers)
    file_handle.print "#{uri}"
    buffers.each { |buf|
        if(!buf.include?(ERROR))
            sum = 0.0
            buf.each { |e|
                sum += Float(e)
            }
            avg = (sum / buf.size)
            file_handle.print ",#{avg}"
        else
            file_handle.print ",#{ERROR}"
        end
    }
    file_handle.puts
end

puts "Reading from '#{options[:data_files].inspect}'..."
puts "Outputting to '#{options[:out_file_path]}'..."
puts

UNSET="<unavailable>"
ERROR="<error>"

node_buffers = Array.new
data_handles = Array.new
out_file_handle = File.open(options[:out_file_path],'w')
data_files = options[:data_files]

data_files.each do |i|
    puts "making handle from #{i}..."
    out_file_handle.print "#{i},"
    data_handles << File.new(i)
    node_buffers << Array.new
end

out_file_handle.puts

print "working..."
REF_POS = 0
GEO_POS = 3
RTT_POS = 12
URI_POS = 13
CLB = "CACHE_LINE_BOOTSTRAP"
FIRST_LINE = true
cached_ref_uri = CLB
while ref_line = data_handles[REF_POS].gets
    print "."
    STDOUT.flush
    matched_uri = UNSET
    ref_line.split(',')[URI_POS].match(/(^http:\/\/[a-zA-Z0-9\.\-]+[a-z0-9][\/]*[a-zA-Z0-9\-\_\.\~\/]*|^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)/)
    ref_match = $1
    if(cached_ref_uri == CLB)
        cached_ref_uri = ref_match
    end
    if(cached_ref_uri != ref_match)
        puts "writing"
        writeBufferVals(out_file_handle,cached_ref_uri,node_buffers)
        (0..node_buffers.size - 1).each { |i|
            node_buffers[i] = Array.new
        }
        cached_ref_uri = ref_match
    end
    if(FIRST_LINE)
        out_file_handle.print("#{ref_line.split(',')[GEO_POS]},")  
    end
    node_buffers[REF_POS] << ref_line.split(',')[RTT_POS]
    (1..data_handles.length - 1).each { |i|
        cpd_line = data_handles[i].gets
        cpd_line.split(',')[URI_POS].match(/(^http:\/\/[a-zA-Z0-9\.\-]+[a-z0-9][\/]*[a-zA-Z0-9\-\_\.\~\/]*|^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)/)
        cpd_match = $1
        if(ref_match == cpd_match)
            if(FIRST_LINE)
                out_file_handle.print(cpd_line.split(',')[GEO_POS])
            end
            node_buffers[i] << cpd_line.split(',')[RTT_POS]
        else
            puts "ERROR DETECTED, FOLLOWING LINES SHOULD MATCH:"
            puts "CACHED_URI: #{cached_ref_uri}"
            puts "COMPRD_URI: #{cpd_match}"
            puts "ref_match: #{ref_match}"
            puts "cpd_file: #{i}"
            exit 1
        end
    }
    if(FIRST_LINE)
        out_file_handle.print("\n")
        FIRST_LINE = false
    end
end
puts "done."
