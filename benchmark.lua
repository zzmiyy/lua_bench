BenchmarkResult = {}
function BenchmarkResult:Init(func_name)
	obj = {}
	obj.call_count = 0
	obj.time_spent = 0
	obj.func_name = func_name

	setmetatable(obj, self)
    self.__index = self;
    return obj
end

function BenchmarkResult:Clear()
	self.call_count = 0;
	self.time_spent = 0;
end

function SortByFName(lhs, rhs)
	return lhs.func_name < rhs.func_name
end

function SortByTotalTime(lhs, rhs)
	return lhs.time_spent < rhs.time_spent
end

function SortByCount(lhs, rhs)
	return lhs.call_count < rhs.call_count
end

function SortAvgTime(lhs, rhs)
	return lhs.time_spent / lhs.call_count < rhs.time_spent / rhs.call_count
end

Benchmark = {
	static = true
}

function Benchmark:Init(...)
	local obj = {}

	obj.results = {}
	obj.max_func_name_len = 0

	setmetatable(obj, self)
    self.__index = self;
    obj.static = false;
    
    obj:WrapTables(...)

    return obj
end

function Benchmark:WrapTables(...)
	local wrap_one = function(obj)
		for name, ptr in pairs(obj) do
			if(type(ptr) == "function") then
				self:WrapFunction(obj, name, ptr)
			end
		end
	end
	for k,v in ipairs({...}) do
		wrap_one(v)
	end
end

function Benchmark:WrapFunction(obj, fnc_name, fnc_ptr)
	if(self.static) then
		print("You try call wrap from static class! Dont do this!")
		return
	elseif self.results[fnc_name] then
		return
	end
 	
	self.max_func_name_len = math.max(self.max_func_name_len, #fnc_name)
	self.results[fnc_name] = BenchmarkResult:Init(fnc_name)

	obj[fnc_name] = function(...)
		local time_start = self.GetCurrentTime()
		local res = fnc_ptr(...)
		self.results[fnc_name].call_count = self.results[fnc_name].call_count + 1
		self.results[fnc_name].time_spent = self.results[fnc_name].time_spent + self.GetCurrentTime() - time_start
		return res
	end

end

function Benchmark:ClearResults()
	for k,v in pairs(self.results) do 
		v.Clear()
	end
end	

function Benchmark:PrintResults(sort_f, print_f)
	if not sort_f then
		sort_f = SortByFName
	end

	if not print_f then
		print_f = print
	end

	local func_name_col = "func name"
	local time_spent_col = "time spent AVG, s"
	local call_count_col = "call count"
	local total_time = "total time, s"

	local adjust_size = function(s, target_len, char)
		if not char then char = " " end
		while(#s < target_len) do
			if(#s % 2 == 1) then
				s = s..char
			else
				s = char..s
			end	
		end
		return s
	end

	adjust_size(func_name_col, self.max_func_name_len)
	local header = string.format("|%s|%s|%s|%s|\n", func_name_col, time_spent_col , call_count_col, total_time)

	print_data = header

	local res = {}

	for k,v in pairs(self.results) do
		res[#res + 1] = v
	end

	table.sort(res, sort_f)

	for _,v in ipairs(res) do
		print_data = print_data..string.format("|%s|%s|%s|%s|\n",
		 adjust_size(v.func_name, #func_name_col),
		 adjust_size(string.format("%f",v.time_spent / v.call_count), #time_spent_col),
	     adjust_size(string.format("%d",v.call_count), #call_count_col),
		 adjust_size(string.format("%f",v.time_spent), #total_time))
	end

	local _end = "end"
	print_data = print_data..adjust_size(_end, #header, "-")

	print_f(print_data)

end

function Benchmark:GetCurrentTime()
	return os.clock()
end

function Benchmark:SetTimeFunction(time_func)
	if not time_func then return end
	self["GetCurrentTime"] = time_func
end

Test = {}

function Test:B()
	os.execute(" ping -n 1 8.8.8.8 > nul")	
end

bench = Benchmark:Init(Test)

function Test:A()
	os.execute(" ping -n 1 8.8.8.8 > nul")	
end

Test:A()
Test:B()
bench:PrintResults()