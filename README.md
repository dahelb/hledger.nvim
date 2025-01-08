# hledger.nvim

## Requirements

- `hledger` with at least version 1.26

## Install

With lazy.nvim

```lua
-- init.lua
{
    "davidhleibg/hledger.nvim"
}


-- plugins/hledger.lua
return {
    {
        "davidhelbig/hledger.nvim"
    }
}
```

Run `:checkhealth hledger` to check if you are ready to go!

## Usage

Currently provides two main functionalities: `check` and `query`.

### Check

Running `:HlCheck` will execute `hledger check` and show potential errors in the current buffer as diagnostics.
Strict mode checking can be performed by appending an exlamation mark: `:HlCheck!`. 
Additional checks can be passed as arguments: `:HlCheck ordereddates` (see help for `hledger check` for available checks).

Optionally, create an autocommand for running checks upon opening and/or after saving.

```lua
--- plugins/hledger.lua
return {
    "davidhelbig/hledger.nvim",
    config = function()
        vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
            pattern = { "*.ledger", "*.journal" },
            callback = function()
                local hledger = require("hledger")
                hledger.check { strict = true }
            end,
        })
    end
}
```

### Query

Use `:HlQuery` to populate the quickfix window with the results of a `hledger query`. Query syntax is the same as on the command line.

```
:HlQuery date:2022 desc:amazon desc:amzn
```

Note: When using the `expr:` syntax, whitespace should be escaped with a backslash `\`, __not__ quotation marks.
```
:HlQuery expr:desc:cool\ AND\ tag:A
```

