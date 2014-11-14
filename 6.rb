#!/usr/bin/env ruby

require 'base64'

def array_hamming_distance(array_1, array_2)
  array_1.zip(array_2).flat_map do |a,b|
    (a^b.to_i).to_s(2).count('1')
  end.reduce(0) { |acc, i| acc + i }
end

file_data = File.read('6.txt')
data = Base64.decode64(file_data)

hamming_distances = (1..64).each_with_object(Hash.new) do |key_length, table|
  total_distance = data
  .each_byte              # Get an array of bytes
  .each_slice(key_length) # Slice it into sub arrays of the key size
  .each_cons(2)           # Grab [a,b], [b,c]. [c,d] where a,b,c,d are sub arrays of key size
  .map do |a,b|
    array_hamming_distance(a,b)     # Find the hamming distance for each element
  end.reduce(0) { |acc,i| acc + i } # Sum the total hamming distance
  # NOTE: We don't divide by length as that weighted length too heavily

  table[key_length] = total_distance
end

# Use a metric found via experimentation, that weights key length
# NOTE: the best matches were often multiples of the key length
# You could expand the search size and lean on Integer#gcd for more robust
# searching.
most_likely_key_length,_ = hamming_distances.min_by { |k,v| k * v**32 }

puts "Most likely key length: #{most_likely_key_length}"

# Make a hash of index modulus -> characters
# Sadly we won't have words so we can't use a dictionary attack
# Like we did in the previous examples
columns = data
.each_char
.group_by
.each_with_index { |datum,i| i % most_likely_key_length }

# This ends up making an array of most_likely_key_length elements
# Each element is the result of reducing the index modulus we made above
# and maximizing the number of space characters we find in that result.
key_array = columns.sort_by { |k,v| k }.reduce(Array.new) do |acc,(k,*v)|
  ascii_target = v.join

  # Try all the keys for this byte
  results = (0..255).each_with_object(Hash.new) do |i,table|
    table[i] = ascii_target.each_byte.map { |byte| (byte ^ i).chr }.join
  end.reject { |i,result|
    result !~ /\w+/ or # If we have no word characters, throw it away
    result.each_char.any? { |char| char.ord > 127 } # Throw away high ascii too
  }

  likely_key,_ = results.max_by do |key,result|
    # Shoutout to Wikipedia:
    # In English, the space is slightly more frequent than the top letter (e) [9]
    result.each_char.count { |char| char == " " } # Optimize for space characters
  end

  # Add our best guess to our key list. We sorted columns by index so we're in order.
  acc << likely_key
end

puts "Likely Key: #{key_array.map { |i| i.chr}.join.inspect}"

# Apply our key to the data
clear_text = data
.each_byte
.each_with_index
.map do |byte,i|
  (byte ^ key_array[i % key_array.length].to_i).chr
end.join

puts "Clear Text:\n #{clear_text}"
