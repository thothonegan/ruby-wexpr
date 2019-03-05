
module Wexpr
	##
	# Common base class for Wexpr Exceptions
	class Exception < RuntimeError
		attr_reader :line
		attr_reader :column
		
		def initialize(line, column, message)
			super(message)
			@line = line
			@column = column
			@message = message
		end
		
		def to_s
			return "#{@line}:#{@column} #{@message}"
		end
	end
	
	# specific instances
	
	class MapMissingEndParenError < Exception
	end
	
	class ExtraDataAfterParsingRootError < Exception
	end
	
	class EmptyStringError < Exception
	end
	
	class InvalidUTF8Error < Exception
	end
	
	class InvalidStringEscapeError < Exception
	end
	
	class ArrayMissingEndParenError < Exception
	end
	
	class MapKeyMustBeAValueError < Exception
	end
	
	class MapNoValueError < Exception
	end
	
	class ReferenceMissingEndBracketError < Exception
	end
	
	class ReferenceInvalidNameError < Exception
	end
	
	class ReferenceInsertMissingEndBracketError < Exception
	end
	
	class ReferenceUnknownReferenceError < Exception
	end
	
end

