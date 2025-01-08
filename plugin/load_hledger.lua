vim.api.nvim_create_user_command('HlQuery', function(opts)
	require("hledger").query(unpack(opts.fargs))
end, { nargs = "*" })

vim.api.nvim_create_user_command(
	"HlCheck",
	function(opts)
		require("hledger").check { strict = opts.bang, additional_checks = opts.fargs }
	end,
	{ nargs = "*", bang = true, desc = "Run hledger check with optional strict mode and additional checks" }
)
