#!/usr/bin/env ruby

require 'openssl'
require 'base64'

@secret = Base64.decode64("Um9sbGluJyBpbiBteSA1LjAKV2l0aCBteSByYWctdG9wIGRvd24gc28gbXkgaGFpciBjYW4gYmxvdwpUaGUgZ2lybGllcyBvbiBzdGFuZGJ5IHdhdmluZyBqdXN0IHRvIHNheSBoaQpEaWQgeW91IHN0b3A/IE5vLCBJIGp1c3QgZHJvdmUgYnkK")

def gen_aes_key
  Random.new.bytes(16) # This isn't secure random for this test
end
@key = gen_aes_key

def gen_noise(size)
  Random.new.bytes(size) # This isn't secure random for this test
end
@noise = gen_noise(rand(64))

def encrypt_ecb(text)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.key = @key
  cipher.encrypt
  cipher.update(@noise + text) + cipher.final
end

def encryption_oracle(text)
  text = text + @secret
  encrypt_ecb(text)
end

def detect_cipher(sample)
  sample_bytes = sample.bytes.each_slice(16).map { |i| i }

  unique_size = sample_bytes.uniq.size
  size = sample_bytes.size

  # ECB will encode the same block the same way, so if there are many duplicated, it is ECB
  if size - unique_size > 3
    puts "Looks like ECB"
  else
    puts "Looks like CBC"
  end
end

# try various different block sizes, summing the bytes.
# Since ECB encrypts the data the same way
# we want to find the key that produces two uniq blocks
# since we gave many duplicate blocks
#
def detect_key_size(sample)
  key_sizes = (8..32).reduce(Hash.new) do |acc, i|
    acc[i] = sample.bytes.each_slice(i).map { |i| i.sum }
    acc
  end

  # + k for a tie breaker between multiples of keysize
  key_bytes = key_sizes.min_by { |k,v| v.uniq.size + k }[0]

  puts "Key size looks like #{key_bytes} bytes / #{key_bytes * 8} bits"
  key_bytes
end

def break_ecb_byte(pad, known, index, noise_blocks)
  block = index / @key_bytes + noise_blocks
  #attack_block = encryption_oracle(pad).bytes[0..index]
  attack_block = encryption_oracle(pad).bytes.each_slice(@key_bytes).map { |i| i }[block][0..index]

  match = (0..255).detect do |byte|
    text = pad + known + byte.chr
    #encrypted_block = encryption_oracle(text).bytes[0..index]
    encrypted_block = encryption_oracle(text).bytes.each_slice(@key_bytes).map { |i| i }[block][0..index]
    encrypted_block == attack_block
  end

  byte = match.chr
end

def detect_noise_blocks(sample)
  # Our sample was generated with a bunch of duplicate blocks.
  # Find the block that gets repeated several times in a row
  sample_bytes = sample.bytes.each_slice(16).map { |i| i }
  known = sample_bytes.group_by { |i| i }.max_by { |k,v| v.size }[0]
  last_known = sample_bytes.index(known)
  last_known
end

def detect_pad_bytes
  blocks = encryption_oracle("").bytes.size / 16

  pad_sizes = (0..16).reduce(Hash.new) do |acc,i|
    acc[i] = encryption_oracle("A" * i).bytes.size / 16
    acc
  end

  pad_bytes = pad_sizes.select { |k,v| v == pad_sizes[0] }. max_by { |k,v| k }[0]
  pad_bytes
end

sample = encryption_oracle("A" * 128)
detect_cipher(sample)
@key_bytes = detect_key_size(sample)

noise_blocks = detect_noise_blocks(sample)
puts "Noise Blocks: #{noise_blocks}"

pad_bytes = [detect_pad_bytes() - 5, 0].max
puts "Pad Bytes: #{pad_bytes}"
puts "----"

pad_length = @key_bytes - 1
known = ""

139.times do |i|
  pad_length = @key_bytes if pad_length == 0
  pad = "A" * (pad_length + pad_bytes)
  byte = break_ecb_byte(pad, known,  i + 1, noise_blocks)
  pad_length -= 1
  known << byte
  # puts known
end
puts known
