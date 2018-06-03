#!/usr/bin/env ruby

require 'openssl'
require 'base64'

INPUT = "L77na/nrFsKvynd6HzOoG7GHTLXsTVu9qvY/2syLXzhPweyyMTJULu/6/kXX0KSvoOLSFQ==".freeze
CIPHER_TEXT = Base64.decode64(INPUT).freeze
KEY = "YELLOW SUBMARINE".freeze
NONCE = 0.freeze

#    key=YELLOW SUBMARINE
#    nonce=0
#    format=64 bit unsigned little endian nonce,
#           64 bit little endian block count (byte count / 16)

def openssl_decrypt_ctr(nonce, cipher_text)
  cipher = OpenSSL::Cipher.new('AES-128-CTR')
  cipher.encrypt
  cipher.key = KEY
  cipher.iv = [nonce,0].pack("<QQ")
  cipher.update(cipher_text) + cipher.final
end

def decrypt_ctr_block(nonce, cipher_block, counter=0, format="<QQ")
  nonce_counter = [nonce, counter].pack(format)
  #puts "Nonce Counter: #{nonce_counter.inspect}"

  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.key = KEY
  cipher.padding = 0
  key_stream = cipher.update(nonce_counter) + cipher.final
  #puts "Key Stream:   #{key_stream.bytes.inspect}"
  #puts "Cipher Block: #{cipher_block.bytes.inspect}"

  plain_text = cipher_block.bytes.zip(key_stream.bytes).map { |k,c| (k ^ c).chr }.join
  #puts "Plain Text:   #{plain_text.bytes.inspect}"
  plain_text
end

def decrypt_ctr(nonce, cipher_text, format="<QQ")
  cipher_blocks = cipher_text.bytes.each_slice(16).map { |slice| slice.map { |byte| byte.chr }.join }
  cipher_blocks.map.with_index do |block, index|
    decrypt_ctr_block(nonce, block, index)
  end.join
end

plain = decrypt_ctr(NONCE, CIPHER_TEXT).inspect
puts plain

new_cipher_text = decrypt_ctr(NONCE, plain)
puts new_cipher_text.inspect
puts CIPHER_TEXT.inspect
puts decrypt_ctr(NONCE, new_cipher_text).inspect

#cipher = decrypt_ctr(NONCE, "Hello World" * 20)
#puts decrypt_ctr(NONCE, cipher).inspect

#openssl_test = openssl_decrypt_ctr(NONCE, "Hello World")
#puts decrypt_ctr(NONCE, openssl_test, "<QQ").inspect
#puts openssl_decrypt_ctr(NONCE, CIPHER_TEXT).inspect
