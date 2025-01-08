local M = {}

local namespace = vim.api.nvim_create_namespace("hledger")

local set_diagnostic = function(diagnostic)
	local bufnr = vim.fn.bufnr(diagnostic.filename, false)

	if bufnr == -1 then
		vim.notify("Diagnostic refers to buffer that is currently not open", vim.log.levels.INFO)
		return
	end

	vim.diagnostic.reset(namespace, bufnr)

	local col = 0
	if diagnostic.col and diagnostic.col > 0 then
		col = diagnostic.col - 1
	end
	local d = {
		bufnr = diagnostic.bufnr,
		lnum = diagnostic.lnum - 1,
		message = diagnostic.message,
		col = col
	}

	vim.diagnostic.set(namespace, bufnr, { d })
end

---@class ErrorLocation
---@field file string The file in which the error occurs
---@field lnum number The starting line of the error
---@field lnum_end? number The line where the error ends
---@field col? number The starting column of the error
---@field col_end? number The column where the error ends

---@param error_line string The error line
---@return ErrorLocation | nil
M.parse_error_line = function(error_line)
	local filename, lnum, end_lnum, col, end_col = error_line:match("hledger: Error: (.-):(%d+)%-?(%d*):(%d*)%-?(%d*):?")

	if not filename and not lnum then
		return
	end

	return {
		filename = filename,
		lnum = tonumber(lnum),
		end_lnum = tonumber(end_lnum),
		col = tonumber(col),
		end_col = tonumber(end_col)
	}
end

---@class ErrorDiagnostic: ErrorLocation
---@field message string A message describing the error

--- Function to parse hledger output
---@param output string The output of `hledger check`
---@return ErrorDiagnostic|nil
M.parse_output = function(output)
	-- Split the output into lines
	local lines = vim.split(output, "\n")

	--[[
	for line in output:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	--]]

	-- First line is the error line
	local error_line = lines[1]
	if not error_line then
		return
	end

	local error_location = M.parse_error_line(error_line)

	if not error_location then
		vim.notify("Could not parse error line", vim.log.levels.ERROR)
		return
	end

	-- Process the remainder lines
	local first_explanation_line = -1
	for i = 2, #lines do
		local line = lines[i]
		-- skip lines with the excerpt (identified by the pipe symbol |)
		if line:find("^%a") then
			first_explanation_line = i
			break
		end
	end

	if first_explanation_line == -1 then
		return
	end

	local explanation = {}
	for i = first_explanation_line, #lines do
		local line = lines[i]
		if i < #lines then
			line = line .. "\n"
		end
		table.insert(explanation, line)
	end

	local message = table.concat(explanation)

	local error_diag = {}
	for k, v in pairs(error_location) do
		error_diag[k] = v
	end
	error_diag.message = message

	return error_diag
end

M.check = function(opts)
	opts = opts or {}

	local strict = opts.strict or true
	local additional_checks = opts.additional_checks or {}

	-- Ensure the current buffer is of type 'ledger'
	if vim.bo.filetype ~= "ledger" then
		vim.notify("Current file is not of type 'ledger'", vim.log.levels.ERROR)
		return
	end

	-- Get the current file path
	local filename = vim.api.nvim_buf_get_name(0)
	if filename == "" then
		vim.notify("No file open", vim.log.levels.ERROR)
		return
	end

	-- Build the hledger command
	local cmd = { "hledger", "check", "-f", filename }
	if strict then
		table.insert(cmd, "--strict")
	end

	if additional_checks then
		for _, check in ipairs(additional_checks) do
			table.insert(cmd, check)
		end
	end

	-- Execute the command using nvim.system()
	vim.system(cmd, { text = true }, vim.schedule_wrap(function(obj)
		if obj.code == 0 then
			vim.diagnostic.reset(namespace)
			return
		end

		if not obj.stderr then
			return
		end

		local diagnostic = M.parse_output(obj.stderr)

		if not diagnostic then
			vim.notify("Error parsing diagnostic", vim.log.levels.DEBUG)
			return
		end

		set_diagnostic(diagnostic)
	end))
end

return M
