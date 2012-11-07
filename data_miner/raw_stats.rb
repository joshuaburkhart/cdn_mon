#!/usr/local/bin/ruby

require 'optparse'

options = {}
optparse = OptionParser.new { |opts|
    opts.banner = <<-EOS
Usage: ruby raw_stats.rb -f /path/to/data/file/1 /path/to/data/file/2 /path/to/data/file/3 [-o /path/to/out/file]

Example 1: ruby raw_stats.rb -f ../test/out.csv
Example 2: ruby raw_stats.rb -f ../test/out.csv ../test2/out.csv -o ../test/out.geoip.csv

Output Format:
uri,RTT avg 1,RTT avg 2,RTT avg N
    EOS
    opts.on('-h','--help','Display this screen') {
        puts opts
        exit
    }
    options[:data_files] = nil
    opts.on('-f','--files FILE1,FILE2,FILEN',Array,'Data File Paths - List CSVs') { |files|
        options[:data_files] = files
    }
    options[:out_file_path] = "#{options[:data_files]}.stats.csv"
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
        avg = buf.inject{ |sum,e| sum + e}.to_f / buf.size
        file_handle.print ",#{avg}"
    }
    file_handle.puts
end

puts "Reading from '#{options[:data_file_path]}'..."
puts "Outputting to '#{options[:out_file_path]}'..."
puts

UNSET="<unavailable>"
ERROR="<error>"

node_buffers = Array.new
data_handles = Array.new
out_file_handle = File.open(options[:out_file_path],'w')
data_files = options[:data_files]

data_files.each do |i|
    out_file_handle.print "#{i}\t"
    data_handles << File.new(i)
    node_buffers << Array.new
end

out_file_handle.puts

print "working..."
cached_ref_uri = nil
while ref_line = data_handles[0].gets
    print "."
    STDOUT.flush
    matched_uri = UNSET
    #validate uri
    ref_line.split(',')[13].match(/(^http:\/\/[a-zA-Z0-9\.\-]+[a-z0-9][\/]*[a-zA-Z0-9\-\_\.\~\/]*|^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)/)
    if(cached_ref_uri == nil)
        cached_ref_uri = $1
    end
    if(cached_ref_uri == $1)
        node_buffers[0] << ref_line.split(',')[12]
        (1..data_handles.length - 1).each_index { |i|
            #while cpd_line = data_handles[i].gets && valid(cpd_line)
            cpd_line.split(',')[13].match(/(^http:\/\/[a-zA-Z0-9\.\-]+[a-z0-9][\/]*[a-zA-Z0-9\-\_\.\~\/]*|^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)/)
            if(cached_ref_uri == $1)
                node_buffers[i] << cpd_line.split(',')[12]
            else
                node_buffers[i] = Array.new
                puts "ERROR DETECTED, FOLLOWING LINES SHOULD MATCH:"
                puts "CACHED_URI: #{cached_ref_uri}"
                puts "COMPRD_URI: #{$1}"
            end
            #end
        }
    else
        writeBufferVals(out_file_handle,cached_ref_uri,node_buffers)
        node_buffers.each { |buf|
            buf = Array.new
        }
        cached_ref_line = nil
    end
end
puts "done."
