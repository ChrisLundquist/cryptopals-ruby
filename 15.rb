#!/usr/bin/env ruby

def generate_valid_pads
  (1..16).map do |i|
    i.chr * i
  end
end

VALID_PADS = generate_valid_pads.freeze

def validate(block_as_string)
  VALID_PADS.any? do |pad|
    block_as_string.end_with?(pad)
  end
end

good = "ICE ICE BABY\x04\x04\x04\x04"
bad5 = "ICE ICE BABY\x05\x05\x05\x05"
bad1234 = "ICE ICE BABY\x01\x02\x03\x04"

[good, bad5, bad1234].each do |example|
  puts example.inspect
  puts validate(example)
end
