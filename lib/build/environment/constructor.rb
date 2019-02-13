# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Build
	class Environment
		Default = Struct.new(:value)
		Replace = Struct.new(:value)
		
		class Define < Struct.new(:klass, :block)
			def initialize(klass, &block)
				super klass, block
			end
			
			def to_s
				"#<#{klass} #{block ? block.source_location.join(':') : 'unknown'}>"
			end
		end
		
		class Constructor
			def initialize(environment)
				@environment = environment
			end
			
			def method_missing(name, *args, **options, &block)
				if block_given? and args.empty?
					@environment[name] = block
					
					return name
				elsif !block_given? and args.any?
					if args.count == 1
						@environment[name] = args.first
					else
						@environment[name] = args
					end
					
					return name
				end
				
				super(name, *args, **options, &block)
			end
	
			def [] key
				@environment[key]
			end
			
			def parent
				@environment.parent
			end
			
			def default(name)
				@environment[name] = Default.new(@environment[name])
				
				return name
			end
			
			def replace(name)
				@environment[name] = Replace.new(@environment[name])
				
				return name
			end
			
			def append(name)
				@environment[name] = Array(@environment[name])
				
				return name
			end
			
			def define(klass, name, &block)
				@environment[name] = Define.new(klass, &block)
				
				return name
			end
		end
		
		def self.combine(*environments)
			# Flatten the list of environments:
			environments = environments.collect do |environment|
				if Environment === environment
					environment.to_a
				else
					environment
				end
			end.flatten
			
			environments.inject(nil) do |parent, environment|
				environment.dup(parent: parent)
			end
		end
		
		def merge(&block)
			self.class.new(self, &block)
		end
		
		# Convert the hierarchy of environments to an array where the parent comes before the child.
		def to_a
			flat = []
			
			flatten_to_array(flat)
			
			return flat
		end
		
		protected
		
		def flatten_to_array(array)
			if @parent
				@parent.flatten_to_array(array)
			end
			
			array << self
		end
	end
end
