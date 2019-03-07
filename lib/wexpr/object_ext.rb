# frozen_string_literal: true

# injections into Object
class Object
	
	#
	# to_wexpr(writeFlags = [])
	# Convert an object to Wexpr. See Wexpr.dump for more information.
	#
	def to_wexpr(writeFlags = [])
		Wexpr.dump self, writeFlags
	end
end
