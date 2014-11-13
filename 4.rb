#!/usr/bin/env ruby

def brute_force_result(target) # From 3.rb
  # Turn our ascii string into cipher_text
  ascii_target = [target].pack("H*")

  # Generate a table of key -> result
  # A given is that the key was one byte
  results = (0..255).each_with_object(Hash.new) do |i,table|
    table[i] = ascii_target.each_byte.map { |byte| (byte ^ i).chr }.join
  end

  # The best result has the most matching words delimited by spaces
  key, likely_clear_text = results.max_by do |key,result|
    tokens = result.split(" ")
    tokens.count { |token| @words[token] }
  end

  likely_clear_text
end

# Make a Hash of a bunch of words to analyze results
@words = Hash.new
File.open("/usr/share/dict/words") do |file|
  file.each_line do |line|
    @words[line.strip] = true
  end
end

puts "Loaded #{@words.keys.length} words"

haystack = File.read("4.txt").split

puts "Loaded #{haystack.length} lines of haystack"

results = haystack.map { |line| brute_force_result(line) }

needle = results.max_by do |line|
    tokens = line.split(" ")
    tokens.count { |token| @words[token] }
end

puts needle
