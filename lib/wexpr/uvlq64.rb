
module Wexpr
	#
	# Helpers for managing VLQ 64bit binary
	#
	module UVLQ64
		#
		# Return the number of bytes which is needed to store a number in the UVLQ64
		#
		def self.byte_size(value)
			# we get 7 bits per byte. 2^7 for each.
			case value
				when 0 ... 128 then return 1 # 2^7
				when 128 ... 16384 then return 2 # 2^14
				when 16384 ... 2097152 then return 3 # 2^21
				when 2097152 ... 268435456 then return 4 # 2^28
				when 268435456 ... 34359738368 then return 5 # 2^35
				when 34359738368 ... 4398046511104 then return 6 # 2^42
				when 4398046511104 ... 562949953421312 then return 7 # 2^49
				when 562949953421312 ... 72057594037927936 then return 8 # 2^56
				when 72057594037927936 ... 9223372036854775808 then return 9 # 2^63
				else
					return 10 # 2^64+
			end
		end
		
		#
		# Write a UVLQ64 (big endian) to a buffer. value -> binary.
		#
		def self.write(value)
			bytesNeeded = byte_size(value)
			
			buf = []
			
			i = bytesNeeded - 1
			for j in 0 .. i
				buf << (((value >> ((i - j) * 7)) & 127) | 128)
			end
			
			buf[i] ^= 128
			
			return buf.pack('C*')
		end
		
		#
		# Read a UVLQ64 big endian from the given buffer. binary -> value
		# Returns the result along with the rest of the buffer not processed
		#
		def self.read(buffer)
			r = 0
			bufferPos = 0
			bufferLen = buffer.size
			
			loop do
				if bufferPos == bufferLen
					raise StandardError("Ran out of buffer processing UVLQ64")
				end
				
				c = buffer[bufferPos].unpack('C')[0]
				r = (r << 7) | (c & 127)
				
				isEnd = (c & 128) == 0
				bufferPos += 1
				break if isEnd
			end
			
			return r, buffer[bufferPos..-1]
		end
	end
end
