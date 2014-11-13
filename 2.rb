#!/usr/bin/env ruby

# Usage ./$0 <r1> <r2>

r1 = ARGV.shift # 1c0111001f010100061a024b53535009181c
r2 = ARGV.shift # 686974207468652062756c6c277320657965

exit 1 if r1.length != r2.length

# Turn our string into decimal ints
r1_hex_array = r1.each_char.map { |c| c.hex }
r2_hex_array = r2.each_char.map { |c| c.hex }

# XOR our parallel arrays, map them back to hex characters, and join it back into a string
xor_hex_array = r1_hex_array.zip(r2_hex_array).flat_map { |r1,r2| (r1 ^ r2).to_s(16) }.join

puts xor_hex_array # 746865206b696420646f6e277420706c6179
