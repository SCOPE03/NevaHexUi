--[[
	NEVAHEXUI test harness.
	Defines the global `NevaTest` used by the generated test bundle. Assertion
	failures are collected per test rather than aborting the run, and the harness
	exits non-zero (via error) when anything failed.
]]

local NevaTest = {}
NevaTest.__index = NevaTest

NevaTest.Cases = {}
NevaTest.CurrentSuite = "general"
NevaTest.Results = {}
NevaTest.Verbose = false

function NevaTest:suite(name)
	self.CurrentSuite = name
end

function NevaTest:test(name, fn)
	table.insert(self.Cases, { suite = self.CurrentSuite, name = name, fn = fn })
end

function NevaTest:fail(message)
	error(message or "assertion failed", 2)
end

function NevaTest:assert(condition, message)
	if not condition then
		self:fail(message or ("expected a truthy value, received " .. tostring(condition)))
	end
	return condition
end

function NevaTest:equals(actual, expected, message)
	if actual ~= expected then
		self:fail(("%s: expected %s, received %s"):format(
			message or "equals",
			tostring(expected),
			tostring(actual)
		))
	end
	return actual
end

function NevaTest:near(actual, expected, tolerance, message)
	tolerance = tolerance or 1e-6
	if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
		self:fail(("%s: expected %s +/- %s, received %s"):format(
			message or "near",
			tostring(expected),
			tostring(tolerance),
			tostring(actual)
		))
	end
	return actual
end

function NevaTest:deepEquals(actual, expected, message)
	local function same(a, b, seen)
		if a == b then
			return true
		end
		if type(a) ~= "table" or type(b) ~= "table" then
			return false
		end
		seen = seen or {}
		if seen[a] == b then
			return true
		end
		seen[a] = b
		for key, value in pairs(a) do
			if not same(value, b[key], seen) then
				return false
			end
		end
		for key in pairs(b) do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	if not same(actual, expected) then
		self:fail(("%s: values are not deeply equal"):format(message or "deepEquals"))
	end
	return actual
end

function NevaTest:throws(fn, message)
	local ok, err = pcall(fn)
	if ok then
		self:fail(message or "expected the call to raise an error")
	end
	return err
end

function NevaTest:contains(haystack, needle, message)
	if type(haystack) == "string" then
		if not haystack:find(needle, 1, true) then
			self:fail(("%s: %q does not contain %q"):format(message or "contains", haystack, tostring(needle)))
		end
		return
	end
	if type(haystack) == "table" then
		for _, item in ipairs(haystack) do
			if item == needle then
				return
			end
		end
		self:fail(("%s: array does not contain %s"):format(message or "contains", tostring(needle)))
		return
	end
	self:fail("contains: unsupported container type " .. type(haystack))
end

function NevaTest:runAll()
	local failures = {}
	local passed = 0
	local startedAt = os.clock()
	for _, case in ipairs(self.Cases) do
		local ok, err = pcall(case.fn)
		if ok then
			passed += 1
			if self.Verbose then
				print(("  PASS  [%s] %s"):format(case.suite, case.name))
			end
		else
			table.insert(failures, { suite = case.suite, name = case.name, error = tostring(err) })
			print(("  FAIL  [%s] %s"):format(case.suite, case.name))
			print(("        %s"):format(tostring(err)))
		end
	end
	local elapsed = os.clock() - startedAt
	print("")
	print(("NEVAHEXUI tests: %d passed, %d failed, %d total (%.3fs)"):format(
		passed,
		#failures,
		#self.Cases,
		elapsed
	))
	if #failures > 0 then
		error(("NEVAHEXUI test suite failed: %d of %d tests failed"):format(#failures, #self.Cases), 0)
	end
	return passed, failures
end

return NevaTest
