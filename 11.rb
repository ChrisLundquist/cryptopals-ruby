#!/usr/bin/env ruby

require 'openssl'
require 'base64'


def gen_aes_key
  Random.new.bytes(16) # This isn't secure random for this test
end

def encrypt_ecb(text)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.key = gen_aes_key
  cipher.encrypt
  cipher.update(text) + cipher.final
end

def encrypt_cbc(text)
  cipher = OpenSSL::Cipher.new('AES-128-CBC')
  cipher.key = gen_aes_key
  cipher.encrypt
  cipher.iv = gen_aes_key
  cipher.update(text) + cipher.final
end

def encryption_oracle(text)
  pad_size = rand(6) + 4 # 5-10 bytes
  pad = Random.new.bytes(pad_size)
  text = pad + text + pad

  if rand(2) == 0
    puts "Using ECB"
    encrypt_ecb(text)
  else
    puts "Using CBC"
    encrypt_cbc(text)
  end
end

sample = encryption_oracle("this is not a love song" * 64)
sample_bytes = sample.bytes.each_slice(16).map { |i| i }

unique_size = sample_bytes.uniq.size
size = sample_bytes.size

# ECB will encode the same block the same way, so if there are many duplicated, it is ECB
if size - unique_size > 3
  puts "Looks like ECB"
else
  puts "Looks like CBC"
end
