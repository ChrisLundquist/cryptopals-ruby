#!/usr/bin/env ruby

require 'openssl'

def gen_aes_key
  Random.new.bytes(16) # This isn't secure random for this test
end
$key = gen_aes_key

def encrypt_ecb(text)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.key = $key
  cipher.update(text) + cipher.final
end

def decrypt_ecb(text)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.decrypt
  cipher.key = $key
  cipher.update(text) + cipher.final
end

# foo=bar&baz=qux&zap=zazzle
# => {"foo"=>"bar", "baz"=>"qux", "zap"=>"zazzle"}
def from_query_param(query_string)
  query_string.split('&').reduce(Hash.new) do |acc, pair|
    k,v = pair.split('=')
    acc[k] = v
    acc
  end
end

# {"foo"=>"bar", "baz"=>"qux", "zap"=>"zazzle"}
# => foo=bar&baz=qux&zap=zazzle
def to_query_param(hash)
  hash.map { |pair| pair.join('=') }.join('&')
end

def profile_for(email)
  profile = {
    email: email,
    uid: 10,
    role: 'user'
  }
  encrypt_profile(profile)
end

def decrypt_profile(cipher_profile)
  profile_string = decrypt_ecb(cipher_profile)
  puts profile_string.inspect
  from_query_param(profile_string)
end

def encrypt_profile(plain_profile)
  profile_string = to_query_param(plain_profile)
  puts profile_string.inspect
  encrypt_ecb(profile_string)
end

email = ARGV.shift || "user@example.com"
admin_block_pad = "A" * 10 # pad so we can bump to the next block so we own all of it

pkcs7_pad_size = 16 - "admin".size
pkcs7_pad = pkcs7_pad_size.chr * pkcs7_pad_size # 11.chr * 11

crafted_admin_block = admin_block_pad + "admin" + pkcs7_pad

# Throw away the first block (00..15 bytes) that has email=AAA...
# This block can be used as a ECB trailer since we crafted the PKCS7 pad
# When used at the end, this block will decrypt as "admin"
admin_ct_block = profile_for(crafted_admin_block)[16..31]

# Generate the middle block that looks like
# com&uid=10&role=
# when decrypted
email_suffix = email[-3..-1] # Pack the end of the email address into this block
profile_pad = "X" * 10 + email_suffix
middle_ct_block = profile_for(profile_pad)[16..31]

# NOTE: This isn't complete, but most emails will fall in the 1-2 block range, not too hard to add more padding
user,host = email.split("@")
effective_host = host[0..-4] # Since we packed the end in the neighboring block

# + 1 for @ that we split on above
str_len = user.size + 1 + effective_host.size

# "email=".size because they prefix us
email_pad_size = 32 - "email=".size - str_len - 1 # -1 for '+'

# "user+XXXXXXXXXXXX@example.com"
padded_email = user + "+" + "X" * email_pad_size + "@" + effective_host


email_ct_blocks = profile_for(padded_email)[0..31]

hacked = email_ct_blocks + middle_ct_block + admin_ct_block
puts "Hacked profile ECB bytes: #{hacked.bytes.inspect}"

# "email=user+XXXXXXXXXXXX@example.com&uid=10&role=admin"
#
# This isn't *quite* what the challenged asked for, but you'd still get the email since characters after + are ignored
# another option is having an email address exactly 13 characters (if you have a 2 digit uid)
# This also looks less suspicious than spurious output if you took a simpler approach like:
# email=u@trustme.com&uid=10&role=admin&uid=10&roluser
# which just munges blocks together
decrypt_profile(hacked)
