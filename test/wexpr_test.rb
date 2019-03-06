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
end
