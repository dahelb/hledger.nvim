local hledger = require("hledger")

describe("error string parsing", function()
	it("should parse line only", function()
		assert.are.same(
			{ filename = "/test/dir/test.journal", lnum = 3 },
			hledger._parse_error_line("hledger: Error: /test/dir/test.journal:3:")
		)
	end)

	it("should parse line and endline", function()
		assert.are.same(
			{ filename = "/test/dir/test.journal", lnum = 3, end_lnum = 5 },
			hledger._parse_error_line("hledger: Error: /test/dir/test.journal:3-5:")
		)
	end)

	it("should parse line, endline, and col", function()
		assert.are.same(
			{ filename = "/test/dir/test.journal", lnum = 3, end_lnum = 5, col = 4 },
			hledger._parse_error_line("hledger: Error: /test/dir/test.journal:3-5:4:")
		)
	end)

	it("should parse line, endline, col and end_col", function()
		assert.are.same(
			{ filename = "/test/dir/test.journal", lnum = 3, end_lnum = 5, col = 4, end_col = 10 },
			hledger._parse_error_line("hledger: Error: /test/dir/test.journal:3-5:4-10:")
		)
	end)

	it("should return nil when error encountered", function()
		assert.is_not_true(
			hledger._parse_error_line("FOOBAR")
		)
	end)
end)

describe("full error output parsing", function()
	it("should parse error", function()
		local stderr = [[hledger: Error: /test/dir/test.ledger:10-12:
10 | 2024-10-01 * This is a test
   |     foo            18 $
   |     bar           -20 $

This transaction is unbalanced.
The real postings' sum should be 0 but is: -2 $
Consider adjusting this entry's amounts, or adding missing postings.]]

		assert.are.same(
			{
				filename = "/test/dir/test.ledger",
				lnum = 10,
				end_lnum = 12,
				message = [[This transaction is unbalanced.
The real postings' sum should be 0 but is: -2 $
Consider adjusting this entry's amounts, or adding missing postings.]]
			},
			hledger._parse_output(stderr)
		)
	end)

	it("should parse errors with double excerpt", function()
		local stderr = [[hledger: Error: /test/dir/test.journal:6:
2 | 2024-10-02 * This is another test
  |     foo              20
  |     bar             -20

6 | 2024-10-01 * This is a test
  | ^^^^^^^^^^
  |     foo              20
  |     bar             -20

Ordered dates checking is enabled, and this transaction's
date (2024-10-01) is out of order with the previous transaction.]]
		assert.are.same(
			{
				filename = "/test/dir/test.journal",
				lnum = 6,
				message = [[Ordered dates checking is enabled, and this transaction's
date (2024-10-01) is out of order with the previous transaction.]]
			},
			hledger._parse_output(stderr)
		)
	end)
end)
