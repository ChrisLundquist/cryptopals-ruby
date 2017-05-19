#!/usr/bin/env ruby

require 'openssl'
require 'base64'

data = File.read("10.txt")
data = Base64.decode64(data)
key = ARGV.shift || "YELLOW SUBMARINE"
iv = ARGV.shift || ([0] * 16)
#iv = iv.pack("C*")

cipher = OpenSSL::Cipher.new('AES-128-ECB')
cipher.key = key
cipher.decrypt

data += ([4] * 16).pack("C*") # So we don't get an exception calling 'final'
intermediate = cipher.update(data)# + cipher.final

cipher_blocks = data.bytes.each_slice(16).map { |i| i }
intermediate_blocks = intermediate.bytes.each_slice(16).map { |i| i }

plain = intermediate_blocks.shift.map { |i| i.chr }.join # The IV is all 0 and a ^ 0 = a
plain += intermediate_blocks.map.with_index { |b,i| b.zip(cipher_blocks[i]).map { |a,b| (a ^ b).chr }.join }.join

puts plain

