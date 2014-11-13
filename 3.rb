#!/usr/bin/env ruby

target = ARGV.shift || '1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736'

# Make a Hash of a bunch of words to analyze results
words = Hash.new
File.open("/usr/share/dict/words") do |file|
  file.each_line do |line|
    words[line.strip] = true
  end
end

puts "Loaded #{words.keys.length} words"

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
  tokens.count { |token| words[token] }
end

puts "Key: #{key}"
puts "Clear Text: #{likely_clear_text}"
