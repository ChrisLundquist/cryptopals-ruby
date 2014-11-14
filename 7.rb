#!/usr/bin/env ruby

require 'openssl'
require 'base64'

data = File.read("7.txt")
data = Base64.decode64(data)
key = ARGV.shift || "YELLOW SUBMARINE"

cipher = OpenSSL::Cipher.new('AES-128-ECB')
cipher.decrypt
cipher.key = key

plain = cipher.update(data) + cipher.final

puts plain
