
require_relative './exception'
require_relative './private_parser_state'

require 'base64'

module Wexpr
	#
	# A wexpr expression - based off of libWexpr's API
	#
	# Expression types:
	# - :null - Null expression (null/nil)
	# - :value - A value. Can be a number, quoted, or token. Must be UTF-8 safe.
	# - :array - An array of items where order matters.
	# - :map - An array of items where each pair is a key/value pair. Not ordered. Keys are required to be values.
	# - :binarydata - A set of binary data, which is encoded in text format as base64.
	# - :invalid - Invalid expression - not filled in or usable
	#
	# Parse flags:
	# - [none currently specified]
	#
	# Write flags:
	# - :humanReadable - If set, will add newlines and indentation to make it more readable.
	#
	class Expression
		# --- Construction functions
		
		#
		# Create an expression from a string.
		# 
		def self.create_from_string(str, parseFlags=[])
			return self.create_from_string_with_external_reference_table(str, parseFlags, {})
		end
		
		#
		# Create an expression from a string with an external reference table.
		#
		def self.create_from_string_with_external_reference_table(str, parseFlags=[], referenceTable={})
			expr = Expression.new()
			expr.change_type(:invalid)
			
			parserState = PrivateParserState.new()
			parserState.externalReferenceMap=referenceTable
			
			# TODO: check that str is valid UTF-8.
			if true
				# now start parsing
				rest = expr.p_parse_from_string(
					str, parseFlags, parserState
				)
				
				postRest = Expression.s_trim_front_of_string(rest, parserState)
				if postRest.size != 0
					raise ExtraDataAfterParsingRootError.new(parserState.line, parserState.column, "Extra data after parsing the root expression: #{postRest}")
				end
				
				if expr.type == :invalid
					raise EmptyStringError.new(parserState.line, parserState.column, "No expression found [remained invalid]")
				end
			else
				raise InvalidUTF8Error.new(0, 0, "Invalid UTF-8")
			end
			
			return expr
		end
		
		# TODO: create_from_binary_chunk
		
		#
		# Creates an empty invalid expression.
		#
		def self.create_invalid()
			expr = Expression.new()
			expr.change_type(:invalid)
			return expr
		end
		
		#
		# Creates a null expression.
		#
		def self.create_null()
			expr = Expression.new()
			expr.change_type(:null)
			return expr
		end
		
		#
		# Creates a value expression with the given string being the value.
		#
		def self.create_value(val)
			expr = Expression.create_null()
			if expr != nil
				expr.change_type(:value)
				expr.value_set(val)
			end
			
			return expr
		end
		
		#
		# Create a copy of an expression. You own the copy - deep copy.
		#
		def create_copy()
			expr = Expression.create_null()
			
			expr.p_copy_from(self)
			
			return expr
		end
		
		# --- Information
		
		#
		# Return the type of the expression
		#
		def type()
			return @type
		end
		
		#
		# Change the type of the expression. Invalidates all data currently in the expression.
		#
		def change_type(type)
			# first destroy
			@value=nil; remove_instance_variable(:@value)
			@binarydata=nil; remove_instance_variable(:@binarydata)
			@array=nil; remove_instance_variable(:@array)
			@map=nil; remove_instance_variable(:@map)
			
			# then set
			@type = type
			
			# then init
			if @type == :value
				@value = ""
			elsif @type == :binarydata
				@binarydata = ""
			elsif @type == :array
				@array = []
			elsif @type == :map
				@map = {}
			end
		end
		
		#
		# Create a string which represents the expression.
		#
		def create_string_representation(indent, writeFlags=[])
			newBuf = self.p_append_string_representation_to_buffer(writeFlags, indent, "")
			
			return newBuf
		end
		
		# TODO: binary version (create_binary_representation)
		
		# --- Values
		
		#
		# Return the value of the expression. Will return nil if not a value
		#
		def value()
			if @type != :value
				return nil
			end
			
			return @value
		end
		
		#
		# Set the value of the expression.
		#
		def value_set(str)
			if @type != :value
				return
			end
			
			@value = str
		end
		
		# --- Binary Data
		
		#
		# Return the binary data of the expression. Will return nil if not binary data.
		#
		def binarydata()
			if @type != :binarydata
				return nil
			end
			
			return @binarydata
		end
		
		#
		# Set the binary data of the expression.
		#
		def binarydata_set(buffer)
			if @type != :binarydata
				return nil
			end
			
			@binarydata = buffer
		end
		
		# --- Array
		
		#
		# Return the length of the array
		#
		def array_count()
			if @type != :array
				return nil
			end
			
			return @array.count
		end
		
		#
		# Return an object at the given index
		#
		def array_at(index)
			if @type != :array
				return nil
			end
			
			return @array[index]
		end
		
		#
		# Add an element to the end of the array
		#
		def array_add_element_to_end(element)
			if @type != :array
				return nil
			end
			
			@array << element
		end
		
		# --- Map
		
		#
		# Return the number of elements in the map
		#
		def map_count()
			if @type != :map
				return nil
			end
			
			return @map.count
		end
		
		#
		# Return the key at a given index
		#
		def map_key_at(index)
			if @type != :map
				return nil
			end
			
			return @map.keys[index]
		end
		
		#
		# Return the value at a given index
		#
		def map_value_at(index)
			if @type != :map
				return nil
			end
			
			return @map.values[index]
		end
		
		#
		# Return the value for a given key in the map
		#
		def map_value_for_key(key)
			if @type != :map
				return nil
			end
			
			return @map[key]
		end
		
		#
		# Set the value for a given key in the map. Will overwrite if already exists.
		#
		def map_set_value_for_key(key, value)
			if @type != :map
				return nil
			end
			
			@map[key] = value
		end
		
		# --- Ruby helpers
		
		#
		# Output as a string - we do a compact style
		#
		def to_s()
			return self.create_string_representation(0, [])
		end
		
		#
		# Convert to a ruby type.
		# Types will convert as follows:
		# - :null - Returns nil
		# - :value - Returns the value as a string.
		# - :array - Returns as an array.
		# - :map - Returns as a hash.
		# - :binarydata - Returns the binary data as a ruby string.
		# - :invalid - Throws an exception
		#
		def to_ruby()
			case @type
				when :null
					return nil
					
				when :value
					return @value
					
				when :array
					a=[]
					for i in 0..self.array_count-1
						a << self.array_at(i).to_ruby
					end
					return a
					
				when :map
					m={}
					for i in 0..self.map_count-1
						k = self.map_key_at(i)
						v = self.map_value_at(i)
						
						m[k] = v.to_ruby
					end
					
					return m
				when :binarydata
					# um, direct i guess - its raw/pure data
					return @binarydata
				else
					raise Exception.new(0,0,"Invalid type to convert to ruby: #{@type}")
			end
		end
		
		# TODO: array operator for array and map
		
		
		# -------------------- PRIVATE ----------------------------
		
		def self.s_is_newline(c)
			return c == '\n'
		end
		
		def self.s_is_whitespace(c)
			# we put \r in whitespace and not newline so its counted as a column instead of a line, cause windows.
			# we dont support classic macos style newlines properly as a side effect.
			return (c == ' ' || c == '\t' || c ==' \r' || self.s_is_newline(c))
		end
		
		def self.s_is_not_bareword_safe(c)
			return (c == '*'               \
				or c == '#'                \
				or c == '@'                \
				or c == '(' or c == ')'    \
				or c == '[' or c == ']'    \
				or c == '^'                \
				or c == '<' or c == '>'    \
				or c == '"'                \
				or c == ';'                \
				or self.s_is_whitespace(c) \
			)
		end
		
		def self.s_is_escape_valid(c)
			return (c == '"' || c == 'r' || c == 'n' || c == 't' || c == '\\')
		end
		
		def self.s_value_for_escape(c)
			return case c
				when '"' then '"'
				when 'r' then '\r'
				when 'n' then '\n'
				when 't' then '\t'
				when '\\' then '\\'
			else
				0 # invalid escape
			end
		end
		
		# trims the given string by removing whitespace or comments from the beginning of the string
		def self.s_trim_front_of_string(str, parserState)
			while true
				if str.size == 0
					return str
				end
				
				first = str[0]
				
				# skip whitespace
				if self.s_is_whitespace(first)
					str = str[1..-1]
					
					if self.s_is_newline(first)
						parserState.line += 1
						parserState.column = 1
					else
						parserState.column += 1
					end
				
				# comment
				elsif first == ';'
					isTillNewline = true
					
					if str.size >= 4
						if str[0..3] == Expression::START_BLOCK_COMMENT
							isTillNewline = false
						end
					end
					
					endIndex = isTillNewline \
						? str.index('\n') \
						: str.index(Expression::END_BLOCK_COMMENT)
					
					lengthToSkip = isTillNewline ? 1 : Expression::END_BLOCK_COMMENT.size
					
					# move forward columns/rows as needed
					parserState.move_forward_based_on_string(
						str[0 .. (endIndex == nil ? (str.size - 1) : (endIndex + lengthToSkip - 1))]
					)
					
					if endIndex == nil or endIndex > (str.size - lengthToSkip)
						str = "" # dead
					else # slice
						str = str[endIndex+lengthToSkip..-1] # skip the comment
					end
				else
					break
				end
			end
			
			return str
		end
		
		# will copy out the value of the string to a new buffer, will parse out quotes as needed
		def self.s_create_value_of_string(str, parserState)
			# two pass:
			# first pass, get the length of the size
			# second pass, store the buffer
			
			bufferLength = 0
			isQuotedString = false
			isEscaped = false
			pos = 0 # position we're parsing at
			
			if str[0] == '"'
				isQuotedString = true
				pos += 1
			end
			
			while pos < str.size
				c = str[pos]
				
				if isQuotedString
					if isEscaped
						# we're in an escape. Is it valid?
						if self.s_is_escape_valid(c)
							bufferLength += 1 # counts
							isEscaped = false # escape ended
						else
							raise InvalidStringEscapeError.new(parserState.line, parserState.column, "Invalid escape found in the string")
						end
					else
						if c == '"'
							# end quote, part of us
							pos += 1
							break
						elsif c == '\\'
							# we're escaping
							isEscaped = true
						else
							# otherwise it's a character
							bufferLength += 1
						end
					end
				else
					# have we ended the word?
					if self.s_is_not_bareword_safe(c)
						# ended - not part of us
						break
					end
					
					# otherwise, its a character
					bufferLength += 1
				end
				
				pos += 1
			end
			
			if bufferLength == 0 and !isQuotedString # cannot have an empty barewords string
				raise EmptyStringError.new(parserState.line, parserState.column, "Was told to parse an empty string")
			end
			
			endVal = pos
			
			# we now know our buffer size and the string has been checked
			# ... not that we needed this in ruby
			buffer = ""
			writePos = 0
			pos = 0
			if isQuotedString
				pos = 1
			end
			
			while writePos < bufferLength
				c = str[pos]
			
				if isQuotedString
					if isEscaped
						escapedValue = self.s_value_for_escape(c)
						buffer[writePos] = escapedValue
						writePos += 1
						isEscaped = false
					else
						if c == '\\'
							# we're escaping
							isEscaped = true
						else
							# otherwise it's a character
							buffer[writePos] = c
							writePos += 1
						end
					end
					
				else
					# it's a character
					buffer[writePos] = c
					writePos += 1
				end
				
				# next character
				pos += 1
			end
			
			return buffer, endVal
		end
		
		# returns information about a string
		def self.s_wexpr_value_string_properties(ref)
			props = {
				:isbarewordsafe => true, # default to being safe
				:needsescaping => false # but we don't need escaping
			}
			
			ref.each_char do |c|
				# for now we cant escape so that stays false
				# bareword safe we're just check for a few symbols
				
				# see any symbols that makes it not bareword safe?
				if self.s_is_not_bareword_safe(c)
					props[:isbarewordsafe] = false
					break
				end
			end
			
			if ref.length == 0
				props[:isbarewordsafe] = false # empty string is not safe since that will be nothing
			end
			
			return props
		end
		
		# returns the indent for the given amount
		def self.s_indent(indent)
			return "  " * indent
		end
		
		# copy an expression into self. lhs should be null cause we dont cleanup ourself atm (ruby note: might not be true).
		def p_copy_from(rhs)
			# copy recursively
			case rhs.type
				when :value
					self.change_type(:value)
					self.value_set(rhs.value)
					
				when :binarydata
					self.change_type(:binarydata)
					self.binarydata_set(rhs.binarydata)
					
				when :array
					self.change_type(:array)
					
					c = rhs.array_count()
					
					for i in 0..c-1
						child = rhs.array_at(i)
						childCopy = child.create_copy()
					
						# add to our array
						self.array_add_element_to_end(childCopy)
					end
					
				when :map
					self.change_type(:map)
					
					c = rhs.map_count()
					
					for i in 0..c-1
						key = rhs.map_key_at(i)
						value = rhs.map_value_at(i)
						
						# add to our map
						self.map_set_value_for_key(key, value)
					end
					
				else
					# ignore - we dont handle this type
			end
		end
		
		# returns the part of the buffer remaining
		# will load into self, setitng up everything. Assumes we're empty/null to start.
		def p_parse_from_binary_chunk(data)
			raise Exception(0, 0, "TODO - binary data")
		end
		
		# returns the part of the string remaining
		# will load into self, setting up everything. Assumes we're empty/null to start.
		def p_parse_from_string(str, parseFlags, parserState)
			if str.size == 0
				raise EmptyStringError(parserState.line, parserState.column, "Was told to parse an empty string")
			end
			
			# now we parse
			str = Expression.s_trim_front_of_string(str, parserState)
			
			if str.size == 0
				return "" # nothing left to parse
			end
			
			# start parsing types
			# if first two characters are #(, we're an array
			# if @( we're a map
			# if [] we're a ref
			# if <> we're a binary string
			# otherwise we're a value.
			if str.size >= 2 and str[0..1] == "#("
				# we're an array
				@type = :array
				@array = []
				
				# move our string forward
				str = str[2..-1]
				parserState.column += 2
				
				# continue building children as needed
				while true
					str = Expression.s_trim_front_of_string(str, parserState)
					
					if str.size == 0
						raise ArrayMissingEndParenError.new(parserState.line, parserState.column, "An array was missing its ending paren")
					end
					
					if str[0] == ")"
						break # done
					else
						# parse as a new expression
						newExpression = Expression.create_null()
						str = newExpression.p_parse_from_string(str, parseFlags, parserState)
						
						# otherwise, add it to our array
						@array << newExpression
					end
				end
				
				str = str[1..-1] # remove the end array
				parserState.column += 1
				
				# done with array
				return str
			elsif str.size >= 2 and str[0..1] == "@("
				# we're a map
				@type = :map
				@map = {}
				
				# move our string accordingly
				str = str[2..-1]
				parserState.column += 2
				
				# build our children as needed
				while true
					str = Expression.s_trim_front_of_string(str, parserState)
					
					if str.size == 0
						raise MapMissingEndParenError.new(parserState.line, parserState.column, "A Map was missing its ending paren")
					end
					
					if str.size >= 1 and str[0] == ")" # end map
						break # done
					else
						# parse as a new expression - we'll alternate keys and values
						# keep our previous position just in case the value is bad
						prevLine = parserState.line
						prevColumn = parserState.column
						
						keyExpression = Expression.create_null()
						str = keyExpression.p_parse_from_string(str, parseFlags, parserState)
						
						if keyExpression.type != :value
							raise MapKeyMustBeAValueError.new(prevLine, prevColumn, "Map keys must be a value")
						end
						
						valueExpression = Expression.create_invalid()
						str = valueExpression.p_parse_from_string(str, parseFlags, parserState)
						
						if valueExpression.type == :invalid
							# it wasn't filled in! no key found.
							# TODO: this changes the error from an upper level, so we'd need to catch and rethrow for this
							raise MapNoValueError.new(prevLine, prevColumn, "Map key must have a value")
						end
						
						# ok we have the key and the value
						self.map_set_value_for_key(keyExpression.value, valueExpression)
					end
				end
				
				# remove the end map
				str = str[1..-1]
				parserState.column += 1
				
				# done with map
				return str
				
			elsif str.size >= 1 and str[0] == "["
				# the current expression being processed is the one the attribute will be linked to.
				
				# process till the closing ]
				endingBracketIndex = str.index ']'
				if endingBracketIndex == nil
					raise ReferenceMissingEndBracketError.new(parserState.line, parserState.column, "A reference [] is missing its ending bracket")
				end
				
				refName = str[1..endingBracketIndex-1]
				
				# validate the contents
				invalidName = false
				for i in 0..refName.size-1
					v = refName[i]
					
					isAlpha = (v >= 'a' && v <= 'z') || (v >= 'A' && v <= 'Z')
					isNumber = (v >= '0' && v <= '9')
					isUnder = (v == '_')
					
					if i == 0 and (isAlpha || isUnder)
					elsif i != 0 and (isAlpha or isNumber or isUnder)
					else
						invalidName = true
						break
					end
				end
				
				if invalidName
					raise ReferenceInvalidNameError.new(parserState.line, parserState.column, "A reference doesn't have a valid name")
				end
				
				# move forward
				parserState.move_forward_based_on_string(str[0..endingBracketIndex+1-1])
				str = str[endingBracketIndex+1..-1]
				
				# continue parsing at the same level : stored the reference name
				resultString = self.p_parse_from_string(str, parseFlags, parserState)
				
				# now bind the ref - creating a copy of what was made. This will be used for the template.
				parserState.internalReferenceMap[refName] = self.create_copy()
				
				# and continue
				return resultString
				
			elsif str.size >= 2 and str[0..1] == "*["
				# parse the reference name
				endingBracketIndex = str.index ']'
				if endingBracketIndex == nil
					raise ReferenceInsertMissingEndBracketError.new(parserState.line, parserState.column, "A reference insert *[] is missing its ending bracket")
				end
				
				refName = str[2 .. endingBracketIndex-1]
				
				# move forward
				parserState.move_forward_based_on_string(
					str[0 .. endingBracketIndex+1-1]
				)
				
				str = str[endingBracketIndex+1 .. -1]
				
				referenceExpr = parserState.internalReferenceMap[refName]
				
				if referenceExpr == nil
					# try again with the external if we have it
					if parserState.externalReferenceMap != nil
						referenceExpr = parserState.externalReferenceMap[refName]
					end
				end
				
				if referenceExpr == nil
					# not found
					raise ReferenceUnknownReferenceError.new(parserState.line, parserState.column, "Tried to insert a reference, but couldn't find it.")
				end
				
				# copy this into ourself
				self.p_copy_from(referenceExpr)
				
				return str
				
			# null expressions will be treated as a value and then parsed seperately
				
			elsif str.size >= 1 and str[0] == "<"
				# look for the ending >
				endingQuote = str.index '>'
				if endingQuote == nil
					# not found
					raise BinaryDataNoEndingError.new(parserState.line, parserState.column, "Tried to find the ending > for binary data, but not found.")
				end
				
				outBuf = Base64.decode64(str[1 .. endingQuote-1-1]) # -1 for starting quote, ending was not part
				if outBuf == nil
					raise BinaryDataInvalidBase64Error.new(parserState.line, parserState.column, "Unable to decode the base64 data")
				end
				
				@type = :binarydata
				@binarydata = outBuf
				
				parserState.move_forward_based_on_string(str[0..endingQuote+1-1])
				
				return str[endingQuote+1 .. -1]
				
			elsif str.size >= 1 # its a value : must be at least one character
				val, endPos = Expression.s_create_value_of_string(str, parserState)
				
				# was it a null/nil string?
				if val == "nil" or val == "null"
					@type = :null
				else
					@type = :value
					@value = val
				end
				
				parserState.move_forward_based_on_string(str[0..endPos-1])
				
				return str[endPos .. -1]
			end
			
			# otherwise, we have no idea what happened
			return ""
		end
		
		# NOTE THESE BUFFERS ARE ACTUALLY MUTABLE
		#
		# Human Readable notes:
		# even though you pass an indent, we assume you're already indented for the start of the object
		# we assume this so that an object for example as a key-value will be writen in the correct spot.
		# if it writes multiple lines, we will use the given indent to predict.
		# it will end after writing all data, no newline generally at the end.
		#
		def p_append_string_representation_to_buffer(flags, indent, buffer)
			writeHumanReadable = flags.include?(:humanReadable)
			type = self.type()
			newBuf = buffer.clone
			
			if type == :null
				newBuf += "null"
				return newBuf
				
			elsif type == :value
				# value - always write directly
				v = self.value
				props = Expression.s_wexpr_value_string_properties(v)
				
				if not props[:isbarewordsafe]
					newBuf += '"'
				end
				
# 				newBuf += v
				
				if not props[:isbarewordsafe]
					newBuf += '"'
				end
				
				return newBuf
				
			elsif type == :binarydata
				# binary data - encode as Base64
				v = Base64.encode64(self.binarydata)
				
				newBuf += "<#{v}>"
				
				return newBuf
				
			elsif type == :array
				arraySize = self.array_count
				
				if arraySize == 0
					# straightforward : always empty structure
					newBuf += "#()"
					return newBuf
				end
				
				# otherwise we have items
				
				# array: human readable we'll write each one on its own line
				if writeHumanReadable
					newBuf += "#(\n"
				else
					newBuf += "#("
				end
				
				for i in 0..arraySize-1
					obj = self.array_at(i)
					
					# if human readable we need to indent the line, output the object, then add a newline
					if writeHumanReadable
						newBuf += Expression.s_indent(indent+1)
						
						# now add our normal
						newBuf = obj.p_append_string_representation_to_buffer(flags, indent+1, newBuf)
						
						# add the newline
						newBuf += "\n"
					else
						# if not human readable, we need to either output theo bject, or put a space then the object
						if i > 0
							# we need a space
							newBuf += " "
						end
						
						# now add our normal
						newBuf = obj.p_append_string_representation_to_buffer(flags, indent, newBuf)
					end
				end
				
				# done with the core of the array
				# if human readable, indent and add the end array
				# otherwise, just add the end array
				if writeHumanReadable
					newBuf += Expression.s_indent(indent)
				end
				newBuf += ")"
				
				# and done
				return newBuf
				
			elsif type == :map
				mapSize = self.map_count()
				
				if mapSize == 0
					# straightforward - always empty structure
					newBuf += "@()"
					return newBuf
				end
				
				# otherwise we have items
				
				# map : human readable we'll write each one on its own line
				if writeHumanReadable
					newBuf += "@(\n"
				else
					newBuf += "@("
				end
				
				for i in 0..mapSize-1
					key = self.map_key_at(i)
					if key == nil
						next # we shouldnt ever get an empty key, but its possible currently in the case of dereffing in a key for some reason : @([a]a b *[a] c)
					end
					
					value = self.map_value_at(i)
					
					# if human readable, indent the line, output the key, space, object, newline
					if writeHumanReadable
						newBuf += Expression.s_indent(indent+1)
						newBuf += key
						newBuf += " "
						
						# add the value
						newBuf = value.p_append_string_representation_to_buffer(flags, indent+1, newBuf)
						
						# add the newline
						newBuf += "\n"
					else
						# if not human readable, just output with spaces as needed
						if i > 0
							# we need a space
							newBuf += " "
						end
						
						# now key, space, value
						newBuf += key
						newBuf += " "
						
						newBuf = value.p_append_string_representation_to_buffer(flags, indent, newBuf)
					end
				end
				
				# done with the core of the map
				# if human readable, indent and add the end map
				# otherwise, just add the end map
				if writeHumanReadable
					newBuf += Expression.s_indent(indent)
				end
				
				newBuf += ")"
				
				# and done
				return newBuf

			else
				raise Exception.new(0,0,"p_append_string_representation_to_buffer - Unknown type to generate string for: {}", type)
			end
		end
		
		START_BLOCK_COMMENT = ";(--"
		END_BLOCK_COMMENT = "--)"
		
		# ----------------- MEMBERS ---------------
		
		# @type - The type of the expression as a Symbol
		# @value - If @type == :value, the string value
		# @binarydata - If @type == :binarydata, the data
		# @array - If @type == :array, will be a ruby array containing the child Expressions.
		# @map - If @type == :map, will be a ruby hash containing teh child Expressions.
		
	end
end

