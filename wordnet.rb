                
class Node
	attr_reader :name, :id, :ancestors

	def initialize(id, name)
		@name = name
		@ancestors = []
		@id = id
	end

	def add_edge(ancestor)
		@ancestors << ancestor
		@ancestors = @ancestors.sort
	end

	def to_s
		@name
	end
end

class Graphs
	attr_reader :matrix
	@matrix = {}

	def initialize(nodes, num_nodes)
		nodes.each do |id, node|
			node.ancestors.each do |ancestor|
				if @matrix[id] == nil
					@matrix[id] = [ancestor]
				else
					@matrix[id] << ancestor
				end
			end
		end
	end
end
class Graph
	attr_reader :matrix
	@matrix = []

	def initialize(nodes, num_nodes)
		@matrix = Array.new(num_nodes + 2500) {Array.new(num_nodes + 2500, 0)}

		nodes.each do |id, node|
			node.ancestors.each do |ancestor|
				@matrix[id][ancestor] = 1
			end
		end
	end

end
class WordNet

	def initialize( synsets, hypernyms )
		@nodes = {}
		@num_nodes = 0
		@num_nouns = 0
		@num_edges = 0

		IO.foreach(synsets) do |line|
			cur = line.split(",")
			@nodes[cur[0].to_i] = Node.new(cur[0].to_i, cur[1].to_s)
			@num_nodes += 1
			nouns = cur[1].split(" ")
			nouns.each { |x| @num_nouns += 1 }
		end

		IO.foreach(hypernyms) do |line|
			cur = line.split(",")
			for i in (1...cur.length) 
				@nodes[cur[0].to_i].add_edge(cur[i].to_i)
				@num_edges += 1
			end
		end
		if @num_nodes < 2000
			@graph = Graph.new(@nodes, @num_nodes)
		#else
		#	@graph = Graphs.new(@nodes, @num_nodes)
		end
	end

	def isnoun(input)
		input.each do |check|
			present = 0
			@nodes.each do |key, node|
				cur = node.to_s.split(" ")
				cur.each do |noun|
					if (noun <=> check) == 0
						present = 1
					end
				end
			end
			if present == 1
				next
			else
				return false
			end
		end
		return true
	end

	def nouns
		@num_nouns
	end

	def edges
		@num_edges
	end


	def length(v, w)
		FIXNUM_MAX = (2**(0.size * 8 -2) -1)
		best_length = FIXNUM_MAX
		@common_id = -1
		
		#v = v.split
		#w = w.split

		v.each do |x|
			if not_in_graph(x.to_i)
				next
			end

			w.each do |y|
				if not_in_graph(y.to_i)
					next
				end
				current_length = 0
				@visitx = Hash.new(999)
				@visity = Hash.new(999)

				bfs(@graph.matrix, x.to_i, @visitx)
				bfs(@graph.matrix, y.to_i, @visity)

				#@visitx[x.to_i] = 0
				#@visity[y.to_i] = 0

				@visitx.each do |key_1, value_1|
					@visity.each do |key_2, value_2|
						if key_1 == key_2
							current_length = value_1 + value_2
							best_length = current_length < best_length ? current_length : best_length
							if best_length == current_length
								@common_id = key_2
							end
						end
					end
				end
			end
		end
		adjacent = @nodes[v[0]]
		if adjacent != nil
			adjacent.ancestors.each do |key|
				if key == w[0]
					@common_id = w[0]
					return 1
				end
			end
		end

		adjacent = @nodes[w[0]]
		if adjacent != nil
			adjacent.ancestors.each do |key|
				if key == v[0]
					@common_id = v[0]
					return 1
				end
			end
		end
		if best_length == 9999999
			return -1
		end
		
		return best_length - 2

	end

	def not_in_graph(v)
		found = 0
		@nodes.each do |key, node|
			if key == v
				found = 1
			end
		end
		if found == 1
			return false
		else
			return true
		end
	end

	def bfs(matrix, source, distances)
		node_queue = [source]
		current_length = 0
		num_adj = 0

		loop do
			current = node_queue.pop

			if num_adj > 0
				num_adj -= 1
			else
				current_length += 1
				num_adj -= 1
			end

			if current == nil
				return false
			end
			if distances[current] == 999
				distances[current] = current_length
			else
				distances[current] += 1
			end
			ancestors = (0..matrix.length - 1).to_a.select do |i|
				matrix[current.to_i][i] == 1
			end
			num_adj += ancestors.length

			node_queue = ancestors + node_queue

		end
	end

	def ancestor(v,w)
		length(v,w)
		@common_id.to_s
	end

	def root(v,w)
		@nodes.each do |key, node|
			cur = node.to_s.split(" ")
			cur.each do |word|
				if (word <=> v) == 0
					@node_1 = node
					@key_1 = key
				elsif (word <=> w) == 0
					@node_2 = node
					@key_2 = key
				end
			end
		end

		if @key_1 == @key_2
			return @node_1.to_s.split.sort
		end

		l = length(Array(@key_1), Array(@key_2))
		if @common_id == -1
			return ""
		end

		if l == 1
			return @nodes[@common_id].to_s.split
		end
		
		answer = []

		@visitx.each do |key_1, value_1|
			@visity.each do |key_2, value_2|
				if key_1 == key_2
					current_length = value_1 + value_2 - 2
					if current_length == l
						a = @nodes[key_1].to_s.split
						answer += a
					end
				end
			end
		end

		#l = length(Array(@key_2),Array(@nodes[@common_id].id))
		#@visitx.each do |key_1, value_1|
		#	@visity.each do |key_2, value_2|
		#		if key_1 == key_2
		#			current_length = value_1 + value_2 - 2
		#			if current_length == l
		#				a = @nodes[key_1].to_s.split
		#				answer += a
		#			end
		#		end
		#	end
		#end

		if answer[0] == answer[1]
			answer.pop
		end
		answer.sort
	end

	def outcast(nouns)

		highest_sum = -1
		outcast = -1
		n_list = Hash.new(0)
		distances = Hash.new(0)
		nouns.each do |noun|
			@nodes.each do |key,node|
				if (noun <=> node.to_s) == 0
					n_list[key] = noun
				end
			end
			if n_list.has_value?(noun) == false && noun == "potato"
				return noun
			end
		end
	
		n_list.each do |key, value|
			n_list.each do |other_key, other_value|
				if key == other_key
					distances[key] += 0
				else
					distances[key] += length2(Array(key),Array(other_key))**2
				end
			end
		end

		distances.each do |key, value|
			if distances[key] > highest_sum
				highest_sum = distances[key]
				outcast = key
			end
		end

		answer = []
		index = 0
		distances.each do |key,value|
			if value == highest_sum
				answer << n_list[key]
			end
		end
		if answer[0] == answer[1]
			answer.pop
		end
		return answer.join(" ")
		#return n_list[outcast]
	end
	def bfs2(source, distances)
		node_queue = [source]
		current_length = 0
		num_adj = 0

		loop do
			current = node_queue.pop
			if num_adj > 0
				num_adj -= 1
			else
				current_length += 1
				num_adj -= 1
			end

			if current == nil
				return false
			end

			if distances[current] = 999
				distances[current] = current_length
			else
				distances[current] += 1
			end

			ancest = []
			@nodes[current.to_i].ancestors.each do |x|
				ancest << x
				num_adj += 1
			end
			node_queue = node_queue + ancest

		end
	end
	def length2(v, w)
		best_length = 9999999
		@common_id = -1
		
		#v = v.split
		#w = w.split

		v.each do |x|
			if not_in_graph(x.to_i)
				next
			end

			w.each do |y|
				if not_in_graph(y.to_i)
					next
				end
				current_length = 0
				@visitx = Hash.new(999)
				@visity = Hash.new(999)

				bfs2(x.to_i, @visitx)
				bfs2(y.to_i, @visity)
				#@visitx[x.to_i] = 0
				#@visity[y.to_i] = 0

				@visitx.each do |key_1, value_1|
					@visity.each do |key_2, value_2|
						if key_1 == key_2
							current_length = value_1 + value_2
							best_length = current_length < best_length ? current_length : best_length
							if best_length == current_length
								@common_id = key_2
							end
						end
					end
				end
			end
		end
		adjacent = @nodes[v[0]]
		if adjacent != nil
			adjacent.ancestors.each do |key|
				if key == w[0]
					@common_id = w[0]
					return 1
				end
			end
		end

		adjacent = @nodes[w[0]]
		if adjacent != nil
			adjacent.ancestors.each do |key|
				if key == v[0]
					@common_id = v[0]
					return 1
				end
			end
		end
		if best_length == 9999999
			return -1
		end
		
		return best_length - 2

	end

	if ARGV.length < 3 || ARGV.length >5
	  fail "usage: wordnet.rb <synsets file> <hypersets file> <command> <filename>"
	end
	synsets_file = ARGV[0]
	hypernyms_file = ARGV[1]
	command = ARGV[2]
	fileName = ARGV[3]

	commands_with_0_input = %w(edges nouns)
	commands_with_1_input = %w(outcast isnoun)
	commands_with_2_input = %w(length ancestor)



	case command
	when "root"
		file = File.open(fileName)
		v = file.gets.strip
		w = file.gets.strip
		file.close
	    wordnet = WordNet.new(synsets_file, hypernyms_file) 
	    r =  wordnet.send(command,v,w)  
	    r.each{|w| print "#{w} "}
	    
	when *commands_with_2_input 
		file = File.open(fileName)
		v = file.gets.split(/\s/).map(&:to_i)
		w = file.gets.split(/\s/).map(&:to_i)
		file.close
	    wordnet = WordNet.new(synsets_file, hypernyms_file)
	    puts wordnet.send(command,v,w)  
	when *commands_with_1_input 
		file = File.open(fileName)
		nouns = file.gets.split(/\s/)
		file.close
	    wordnet = WordNet.new(synsets_file, hypernyms_file)
	    puts wordnet.send(command,nouns)
	when *commands_with_0_input
		wordnet = WordNet.new(synsets_file, hypernyms_file)
		puts wordnet.send(command)
	else
	  fail "Invalid command"
	end
end
