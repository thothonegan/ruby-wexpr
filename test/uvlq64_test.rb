
require "test_helper"

class UVLQ64Test < Minitest::Test
	def test_uvlq64_can_encode_and_decode()
		x = [
			# we use big endian for all this due to uvlq64
			0x7f,
			0x4000,
			0x0,
			0x3ffffe,
			0x1fffff,
			0x200000,
			0x3311a1234df31413
		]
		
		x.each do |v|
			newBuf = Wexpr::UVLQ64::write(v)
			refute_equal nil, newBuf
			
			number, newBuf = Wexpr::UVLQ64::read(newBuf)
			refute_equal nil, newBuf
			assert_equal v, number
		end
	end
end
