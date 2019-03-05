
module Wexpr
	#
	# Internal class which manges the parser state when parsing
	#
	class PrivateParserState
		attr_accessor :line
		attr_accessor :column
		attr_accessor :internalReferenceMap
		attr_accessor :externalReferenceMap
		
		def initialize()
			# start at beginning of file
			@line = 1
			@column = 1
			@internalReferenceMap = {}
			@externalReferenceMap = {}
		end
		
		def move_forward_based_on_string(str)
			str.each_char do |c|
				if c == '\n' # newline
					@line += 1
					@column = 1
				else
					@column = 1
				end
			end
		end
		
		# --- MEMBERS
		
		# @line - The line number
		# @column - The column
		# @internalReferenceMap - The internal reference map from within the file. Takes priority.
		# @externalReferenceMap - The external reference map provided by the user.
	end
end
