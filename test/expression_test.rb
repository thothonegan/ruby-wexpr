require "test_helper"

class ExpressionTest < Minitest::Test
	def test_can_create_null()
		e = Wexpr::Expression.create_null()
		assert_equal e.type, :null
	end
	
	def test_can_create_value()
		e = Wexpr::Expression.create_from_string("val")
		
		assert_equal :value, e.type
		assert_equal "val", e.value
	end
	
	def test_can_create_quoted_value()
		e = Wexpr::Expression.create_from_string(%q["val"])
		
		assert_equal :value, e.type
		assert_equal "val", e.value
	end
	
	def test_can_create_escaped_value()
		e = Wexpr::Expression.create_from_string(%q["val\""])
		
		assert_equal :value, e.type
		assert_equal "val\"", e.value
	end
	
	def test_can_create_number()
		e = Wexpr::Expression.create_from_string("2.45")
		
		assert_equal :value, e.type
		assert_equal "2.45", e.value
	end
	
	def test_can_create_array()
		e = Wexpr::Expression.create_from_string("#(1 2 3)")
		
		assert_equal :array, e.type
		assert_equal 3, e.array_count
		
		assert_equal :value, e.array_at(0).type
		assert_equal "1", e.array_at(0).value
		
		assert_equal :value, e.array_at(1).type
		assert_equal "2", e.array_at(1).value
		
		assert_equal :value, e.array_at(2).type
		assert_equal "3", e.array_at(2).value
	end
	
	def test_can_create_map()
		e = Wexpr::Expression.create_from_string("@(a b c d)")
		
		assert_equal e.type, :map
		assert_equal e.map_count, 2
		
		# ordering is undetermined so we find stuff, then check stuff
		foundA = false
		foundC = false
		
		for i in 0..e.map_count-1
			k = e.map_key_at(i)
			v = e.map_value_at(i).value
			
			if k == "a" and v == "b" and not foundA
				foundA = true
			elsif k == "c" and v == "d" and not foundC
				foundC = true
			else
				assert false, "Unknown item: #{k} = #{v}"
			end
		end
		
		assert foundA and foundC
	end
	
	def test_can_understand_reference()
		e = Wexpr::Expression.create_from_string(%q[@(first [val]"name")])
		
		assert :map, e.type
		assert "name", e.map_value_for_key("first")
	end
	
	def test_can_deref_reference()
		e = Wexpr::Expression.create_from_string(%q[@(first [val]"name" second *[val])])
		
		assert :map, e.type
		assert "name", e.map_value_for_key("first") 
		assert "name", e.map_value_for_key("second")
	end
	
	def test_can_deref_array_reference()
		e = Wexpr::Expression.create_from_string(%q[@(first [val]#(1 2) second *[val])])
		
		assert_equal :map, e.type
		assert_equal :array, e.map_value_for_key("second").type
		assert_equal 2, e.map_value_for_key("second").array_count
		assert_equal "1", e.map_value_for_key("second").array_at(0).value
		assert_equal "2", e.map_value_for_key("second").array_at(1).value
	end
	
	def test_can_deref_map_reference()
		e = Wexpr::Expression.create_from_string(%q[@(first [val]@(a b) second *[val])])
		
		assert_equal :map, e.type
		assert_equal :map, e.map_value_for_key("second").type
		assert_equal 1, e.map_value_for_key("second").map_count
		assert_equal "b", e.map_value_for_key("second").map_value_for_key("a").value
	end
	
	def test_can_deref_from_external_table()
		e = Wexpr::Expression.create_from_string_with_external_reference_table(
			"@(playerName *[name])", [], {
				"name" => Wexpr::Expression.create_from_string("Bob")
			}
		)
		
		assert_equal :map, e.type
		assert_equal "Bob", e.map_value_for_key("playerName").value
	end
	
	def test_can_change_type()
		e = Wexpr::Expression.create_null()
		e.change_type(:value)
		
		assert_equal :value, e.type
	end
	
	def test_can_set_value()
		e = Wexpr::Expression.create_null()
		e.change_type :value
		e.value_set "asdf"
		
		assert_equal "asdf", e.value
	end
	
	def test_can_add_to_array()
		e = Wexpr::Expression.create_null()
		e.change_type :array
		
		e2 = Wexpr::Expression.create_value("a")
		e.array_add_element_to_end(e2)
		
		e3 = Wexpr::Expression.create_value("b")
		e.array_add_element_to_end(e3)
		
		e4 = Wexpr::Expression.create_value("c")
		e.array_add_element_to_end(e4)
		
		assert_equal :array, e.type
		assert_equal "a", e.array_at(0).value
		assert_equal "b", e.array_at(1).value
		assert_equal "c", e.array_at(2).value 
	end
	
	def test_can_set_in_map()
		e = Wexpr::Expression.create_null()
		e.change_type :map
		
		e.map_set_value_for_key("key", 
			Wexpr::Expression.create_from_string("value")
		)
		
		v = e.map_value_for_key("key")
		
		assert_equal :value, v.type
		assert_equal "value", v.value
	end
	
	def test_can_handle_null_expression()
		e = Wexpr::Expression.create_from_string("null")
		e2 = Wexpr::Expression.create_from_string("nil")
		
		assert_equal :null, e.type
		assert_equal :null, e2.type
	end
	
	def test_can_handle_binary_expression()
		e = Wexpr::Expression.create_from_string("<aGVsbG8=>")
		
		assert_equal :binarydata, e.type
		assert_equal "hello", e.binarydata
	end
	
	# this is messing up for some reason, checking though its internal
	def test_is_newline_whitespace()
		assert Wexpr::Expression.s_is_newline("\n")
		assert Wexpr::Expression.s_is_whitespace("\n")
		assert Wexpr::Expression.s_is_not_bareword_safe("\n")
	end
end
