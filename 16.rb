#!/usr/bin/env ruby

require 'openssl'

PREFIX = "comment1=cooking%20MCs;userdata=".freeze
POSTFIX = ";comment2=%20like%20a%20pound%20of%20bacon".freeze

def gen_aes_key
  Random.new.bytes(16) # This isn't secure random for this test
end
$key = gen_aes_key

def encrypt_cbc(text)
  cipher = OpenSSL::Cipher.new('AES-128-CBC')
  cipher.encrypt
  cipher.key = $key
  cipher.update(text) + cipher.final
end

def decrypt_cbc(text)
  cipher = OpenSSL::Cipher.new('AES-128-CBC')
  cipher.decrypt
  cipher.key = $key
  cipher.update(text) + cipher.final
end

def parse_cookie(cookie)
  hash = cookie.split(';').reduce(Hash.new) do |acc,pair|
    k,v = pair.split('=')
    acc[k] = v
    acc
  end
  hash
end

def clean_data(user_data)
  user_data.gsub!(';', '%3b')
  user_data.gsub!('=', '%3d')
  user_data
end

def is_admin?(cookie_hash)
  cookie_hash['admin']
end

def decrypt_and_parse(encrypted_cookie)
  cookie = decrypt_cbc(encrypted_cookie)
  cookie = parse_cookie(cookie)
  cookie
end

def make_cookie(user_data)
  cookie = PREFIX + clean_data(user_data) + POSTFIX
  #puts "making cookie: #{cookie.inspect}"
  encrypted_cookie = encrypt_cbc(cookie)
end

raise "need padding to align with prefix" if PREFIX.size % 16 != 0

pad = "A" * 15
candidates = (0..255).map do |byte|
  # Note: ':' is one less than ';' and '<' is one less than '='
  candidate = make_cookie(pad + byte.chr + ":admin<true").bytes
end

ct_bytes = candidates.detect do |candidate|
  # We want to find a candidate that has both LSBits cleared so we can increment them
  # and we will get the desired result when they are XOR'd
  candidate[PREFIX.size + 0] & 0x01 == 0 && candidate[PREFIX.size + 6] & 0x01 == 0
end

ct_bytes[PREFIX.size + 0] = ct_bytes[PREFIX.size + 0] + 1
ct_bytes[PREFIX.size + 6] = ct_bytes[PREFIX.size + 6] + 1

admin = decrypt_and_parse(ct_bytes.map { |i| i.chr }.join)
puts admin.inspect
puts "Is Admin: #{is_admin?(admin).inspect}"
