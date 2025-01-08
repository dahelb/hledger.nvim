local M = {}

local get_hledger_version = function()
	local handle = io.popen("hledger --version 2>&1")

	local out = handle:read("*a");
	local success, _, exit_code = handle:close()

	if exit_code ~= 0 and not out then
		return
	end

	local major, minor, patch = out:match("hledger (%d+).(%d+).?(%d*)")

	return {
		major = tonumber(major),
		minor = tonumber(minor),
		patch = tonumber(patch)
	}
end

M.check = function()
	vim.health.start("hledger report")

	local version = get_hledger_version()

	if version and version.major and version.minor then
		local version_string
		if version.patch then
			version_string = string.format("%d.%d.%d", version.major, version.minor, version.patch)
		else
			version_string = string.format("%d.%d", version.major, version.minor)
		end

		if version.major < 1 and version.minor < 26 then
			vim.health.error("hledger v" .. version_string .. "found, but need as least version 1.26",
				"Update hldedger to a newer version")
		else
			vim.health.ok("hledger v" .. version_string .. " found")
		end
	else
		vim.health.error("Error parsing version string from hledger", "Make sure hledger is installed and in your PATH")
	end
end

return M
