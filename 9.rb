#!/usr/bin/env ruby

length = (ARGV.shift || "20").to_i
message = ARGV.any? ? ARGV.join(" ") : "YELLOW SUBMARINE"

remainder = length - message.length
exit 1 if remainder < 0

encoded = message.each_char.to_a + [remainder.chr] * remainder

puts encoded.inspect
