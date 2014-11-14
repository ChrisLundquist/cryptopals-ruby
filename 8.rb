#!/usr/bin/env ruby

require 'openssl'

data = File.read("8.txt").split
data.map! { |hex_string| [hex_string].pack("H*") }

# A line has 10 16 byte blocks or 160 bytes
# Make an array of hashes that map block -> count
results = data.map do |line|
  line
  .each_char
  .each_slice(16)
  .reduce(Hash.new {0}) { |acc,slice|
    acc[slice.join] += 1; acc
  }
end

# If we find the same block in a line multiple times, we have a match
result,index = results.each_with_index.detect { |result,i| result.any? { |k,v| v > 1 } }

puts "Likely AES-ECB-128 line: #{index}"

string,count = result.max_by { |k,v| v }

puts "Block #{string.each_byte.to_a} was repeated #{count} times"
