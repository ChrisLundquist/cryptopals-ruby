#!/usr/bin/env ruby

to_encrypt = \
"Burning 'em, if you ain't quick and nimble
I go crazy when I hear a cymbal"

key = ARGV.shift || "ICE"

encrypt_text = to_encrypt
.each_byte       # Make an array of bytes
.each_with_index # Tap the array and add an index to our block
.map do |byte,i| # Map the given byte with the XOR of the appropriate key byte
  (byte ^ key[i % key.length].ord).chr
end.join

# Turn our cipher text into a hex string
hex = encrypt_text.unpack("H*").first

puts hex
