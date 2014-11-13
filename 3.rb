#!/usr/bin/env ruby

target = ARGV.shift || '1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736'

words = Hash.new
File.open("/usr/share/dict/words") do |file|
  file.each_line do |line|
    words[line.strip] = true
  end
end

puts "Loaded #{words.keys.length} words"

ascii_target = [target].pack("H*")

results = (0..255).map do |i|
  ascii_target.each_byte.map { |byte| (byte ^ i).chr }.join
end

likely_clear_text = results.max_by do |result|
  tokens = result.split(" ")
  tokens.count { |token| words[token] }
end

key = results.find_index(likely_clear_text)

puts "Key: #{key}"
puts "Clear Text: #{likely_clear_text}"

