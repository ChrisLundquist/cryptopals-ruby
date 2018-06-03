#!/usr/bin/env ruby

require 'openssl'
require 'base64'

def generate_valid_pads
  (1..16).map do |i|
    i.chr * i
  end
end

def gen_aes_key
  Random.new.bytes(16) # This isn't secure random for this test
end

$key = gen_aes_key
$iv = gen_aes_key
VALID_PADS = generate_valid_pads.freeze

def validate_pad(block_as_string)
  VALID_PADS.any? do |pad|
    block_as_string.end_with?(pad)
  end
end

def encrypt_cbc(text)
  cipher = OpenSSL::Cipher.new('AES-128-CBC')
  cipher.encrypt
  cipher.key = $key
  #cipher.iv = $iv
  cipher.update(text) + cipher.final
end

def decrypt_cbc(text)
  cipher = OpenSSL::Cipher.new('AES-128-CBC')
  cipher.decrypt
  cipher.key = $key
  #cipher.iv = $iv
  cipher.update(text) + cipher.final
end

def server_verify(encrypted_data, debug=false)
  decrypted = decrypt_cbc(encrypted_data)
  if debug
	puts "verifying..."
	puts decrypted.inspect
  end
  return validate_pad(decrypted)
end

def add_pkcs7(message, blocksize=16)
  remainder = blocksize - (message.size % blocksize)
  message + ([remainder.chr] * remainder).join
end

def remove_pkcs7(message)
  pad = VALID_PADS.detect do |pad|
    message =~ /#{pad}$/
  end
  message.sub(/#{pad}$/, '')
end

lines = File.read("./17.txt").split.map { |line| Base64.decode64(line) }
# lines.each { |line| puts line.size }

encrypted_lines = lines.map { |line| encrypt_cbc(add_pkcs7(line)) }

# Check our padding works correctly
correctly_padded = encrypted_lines.all? { |line| server_verify(line) }
raise "setup error" unless correctly_padded

# Check we setup our key and iv correctly
correctly_encrypted = encrypted_lines.all? { |line| decrypt_cbc(line) }
raise "decrypt setup error" unless correctly_encrypted

# Check we can correctly undo both the above
correctly_invertable = encrypted_lines.zip(lines).all? { |enc,plain| plain == remove_pkcs7(decrypt_cbc(enc)) }
raise "incorrect bijection" unless correctly_invertable

# Cool, now we can actually get to work now that we've verified the setup

def find_pad_byte(c1, c2, index=-1)
  good_byte = (0..255).detect do |byte|
    c1[index] = byte
    begin
      server_verify( (c1 + c2).map { |i| i.chr }.join, true)
    rescue
      next nil
    end
    true
  end

  puts good_byte.inspect
  good_byte
end

target_line = encrypted_lines[1]

target_slices = target_line.bytes.each_slice(16).to_a

c1 = target_slices[0]
c2 = target_slices[1]

find_pad_byte(c1, c2)

