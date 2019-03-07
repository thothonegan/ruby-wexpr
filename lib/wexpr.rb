require 'wexpr/exception'
require 'wexpr/expression'
require 'wexpr/object_ext'
require 'wexpr/uvlq64'
require 'wexpr/version'

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
	# See possible writeflags in Expression.
	#
	def self.dump(variable, writeFlags=[])
		# first step, go through the variable and create the equivilant wexpr expressions
		expr = Expression::create_from_ruby(variable)
		
		# then have it write out the string
		return expr.create_string_representation(0, writeFlags)
	end
	
end
