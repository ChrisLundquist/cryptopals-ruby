#!/usr/bin/env ruby

require 'base64'

data = ARGV.shift || "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d"

ascii = [data].pack('H*')
# Challenge text: "I'm killing your brain like a poisonous mushroom"
encoded = Base64.encode64(ascii).gsub("\n",'')
puts encoded
