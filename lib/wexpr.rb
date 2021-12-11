require_relative 'wexpr/exception'
require_relative 'wexpr/expression'
require_relative 'wexpr/object_ext'
require_relative 'wexpr/uvlq64'
require_relative 'wexpr/version'

#
# Ruby-Wexpr library
#
# Currently does not handle Binary Wexpr.
#
module Wexpr
	#
	# Parse Wexpr and turn it into a ruby hash
	# Will thrown an Exception on failure
	#
	def self.load(str, flags=[])
		expr = Expression::create_from_string(str, flags)
		return expr.to_ruby
	end
	
	#
	# Emit a hash as the equivilant wexpr string, human readable or not.
	# See possible writeflags in Expression. We also support :returnAsExpression which will return the expression, and not the string (for internal use).
	#
	def self.dump(variable, writeFlags=[])
		# first step, go through the variable and create the equivilant wexpr expressions
		expr = Expression::create_from_ruby(variable)
		
		if writeFlags.include? :returnAsExpression
			return expr
		end
		
		# then have it write out the string
		return expr.create_string_representation(0, writeFlags)
	end
	
end
