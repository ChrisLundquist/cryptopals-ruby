#!/usr/bin/env ruby

require 'openssl'
require 'base64'

KEY = Random.new.bytes(16) #"YELLOW SUBMARINE".freeze #Random.new.bytes(16)
NONCE = 0.freeze
FREQUENCY = {
    " ": 14.0,
    "a": 8.167,
    "b": 1.492,
    "c": 2.782,
    "d": 4.253,
    "e": 12.702,
    "f": 2.228,
    "g": 2.015,
    "h": 6.094,
    "i": 6.966,
    "j": 0.153,
    "k": 0.772,
    "l": 4.025,
    "m": 2.406,
    "n": 6.749,
    "o": 7.507,
    "p": 1.929,
    "q": 0.095,
    "r": 5.987,
    "s": 6.327,
    "t": 9.056,
    "u": 2.758,
    "v": 0.978,
    "w": 2.360,
    "x": 0.150,
    "y": 1.974,
    "z": 0.074
}.freeze

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

def line_to_blocks(line)
  line.bytes.each_slice(16).to_a
end

# takes our blocks and turns them into vectors by byte index
# Transposing them so we can see what xor key works best for a column
def blocks_to_vector(blocks)
  target_vectors = 16.times.reduce(Array.new) do |acc, block_index|
    acc << blocks.map { |block| Array(block)[block_index] }
  end
end

# 1. look at each byte index and calculate which key stream byte makes printable characters
# 2. store the frequency of printable characters in a hash for later.
# 3. ignore keys that produced 0 printable characters
def keys_for_vector(vector)
  (0..255).reduce(Hash.new) do |acc,byte|
    # 0x20..0x7E is the ascii printable character range
    only_printable = vector.all? { |target| (0x20..0x7E).include?(byte ^ target.to_i) }
    next acc unless only_printable

    score = vector.sum do |target|
      candidate = (byte ^ target.to_i)
      #puts "Candidate #{candidate.chr.downcase}"
      value = FREQUENCY[candidate.chr.downcase.to_sym].to_f
      #puts value
      value
    end
    #puts "Byte #{byte}: score #{score}"

    acc[byte] = score if score > 0
    acc
  end
end

# +possible_keys+ is now an array of hashes with 16 elements ( one for each byte in the block )
# Each hash is the frequency table for which key produced how many printable characters
def probably_key_for_block(block_vectors)
  possible_keys = block_vectors.map { |vector| keys_for_vector(vector) }
  possible_keys.map { |table| table.max_by { |k,v| v.to_i }&.first }
end

encrypted_lines = File.read("./20.txt").split.map do |line|
  decrypt_ctr(NONCE, Base64.decode64(line))
end

# chop up our lines into encypted blocks so each line becomes an array of blocks.
target_block_lines = encrypted_lines.map { |line| line_to_blocks(line) }
#puts target_block_lines.map { |line| line.last.size }

# Take the first block of each line
#target_blocks = target_block_lines.map { |block_line| block_line[0] }
longest_block_chain = target_block_lines.max_by { |i| i.size }.size
# puts longest_block_chain.inspect

block_keys = longest_block_chain.times.reduce(Array.new) do |acc, block_id|
  target_blocks = target_block_lines.map { |line| line[block_id] }
  target_vectors = blocks_to_vector(target_blocks)
  block_key = probably_key_for_block(target_vectors)
  acc << block_key
end
puts block_keys.inspect

decrypted = encrypted_lines.map do |line|
  line.bytes.map.with_index do |byte, index|
    ( byte.to_i ^ block_keys.flatten[index].to_i ).chr
  end.join
end

puts decrypted

