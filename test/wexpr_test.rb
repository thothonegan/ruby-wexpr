require "test_helper"

class WexprTest < Minitest::Test
	def test_that_it_has_a_version_number
		refute_nil ::Wexpr::VERSION
	end

	def test_can_load_value
		val = Wexpr.load("asdf")
		assert_equal "asdf", val
	end
	
	def test_can_load_complex
		val = Wexpr.load("@(array #(1 2 3) map @(a b c d))")
		expected = {"array" => ["1", "2", "3"], "map" => {"a" => "b", "c" => "d"} }
		assert_equal expected, val
	end
	
	def test_can_load_newlines
		val = Wexpr.load("@(\n)")
		assert_equal Hash, val.class
	end
	
	def test_can_load_with_ending_newline
		val = Wexpr.load("@()\n")
		assert_equal Hash, val.class
	end
	
	def test_can_dump
		hash = {
			"array" => [1, 2, 3],
			"map" => { "v" => "9" },
			"number" => 99
		}
		
		str = Wexpr.dump(hash)
		
		# the order it might return the types is undefined, so our best way of testing
		# is just to return it back to an hash and compare
		hash2 = Wexpr.load(str)
		
		# it manipulates it slightly due to how values work, so adjust for that
		expectedHash = {
			"array" => ["1", "2", "3"],
			"map" => { "v" => "9" },
			"number" => "99"
		}
		
		assert_equal expectedHash, hash2
	end
	
	def test_can_use_to_wexpr
		assert_equal "hi", "hi".to_wexpr
		assert_equal "9", 9.to_wexpr
		assert_equal "#(1 2 3)", [1, 2, 3].to_wexpr
	end
end
