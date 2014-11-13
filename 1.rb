#!/usr/bin/env ruby

require 'base64'

data = STDIN.read or ARGV

ascii = [data].pack('H*')
# Challenge text: "I'm killing your brain like a poisonous mushroom"
encoded = Base64.encode64(ascii).gsub("\n",'')
puts encoded
