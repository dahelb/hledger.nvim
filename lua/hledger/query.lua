local M = {}


-- Run the hledger command
local function run_hledger_command(query_args, filename)
	-- Construct the command as a list
	local cmd = { "hledger", "-I", "-f", filename, "print", "-O", "json", unpack(query_args) }

	-- Execute the command using vim.system
	local result = vim.system(cmd):wait()

	-- Check for errors
	if result.code ~= 0 then
		error("hledger command failed: " .. result.stderr)
	end

	-- Return the stdout (output) of the command
	return result.stdout
end


-- Parse JSON output
local function parse_hledger_json(output)
	local ok, data = pcall(vim.json.decode, output)
	if not ok then
		error("Failed to parse JSON: " .. tostring(data))
	end

	local quickfix = {}
	for _, posting in ipairs(data) do
		table.insert(quickfix, {
			lnum = posting["tsourcepos"][1]["sourceLine"],
			end_lnum = posting["tsourcepos"][2]["sourceLine"],
			filename = posting["tsourcepos"][1]["sourceName"],
			text = posting["tdate"] .. " " .. posting["tdescription"]
		}
		)
	end

	return quickfix
end

-- Populate the quickfix list
local function set_quickfix_list(quickfix_list)
	vim.fn.setqflist({}, ' ', {
		title = "Hledger Results",
		items = quickfix_list
	})
	vim.cmd('copen') -- Open the quickfix list
end

M.query = function(...)
	local args = { ... }

	-- Ensure we have at least one argument
	if #args == 0 then
		vim.notify("No query arguments provided", vim.log.levels.ERROR)
		return
	end


	-- Check if the current filetype is 'ledger'
	local filetype = vim.bo.filetype
	if filetype ~= "ledger" then
		vim.notify("Current file is not of type 'ledger'", vim.log.levels.ERROR)
		return
	end

	-- Get the current buffer's filename
	local filename = vim.api.nvim_buf_get_name(0)
	if filename == "" then
		vim.notify("No file open", vim.log.levels.ERROR)
		return
	end

	-- Run the hledger command
	local output = run_hledger_command(args, filename)
	if not output or output == "" then
		vim.notify("No results from hledger", vim.log.levels.INFO)
		return
	end

	-- Parse the output and populate quickfix
	local quickfix_list = parse_hledger_json(output)
	set_quickfix_list(quickfix_list)
end

return M
