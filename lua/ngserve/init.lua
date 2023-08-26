local M = {}

local spawned_processes = {}

local function add_process(pid)
	table.insert(spawned_processes, pid)
end

M.serve = function()
	local Job = require("plenary.job")

	local job = Job:new({
		cwd = vim.fn.getcwd(),
		command = "ng",
		args = { "serve" },
		on_stdout = function(a, b, c)
			print("on_stdout: ", a, b, c)
		end,
		on_stderr = function(a, b, c)
			print("on_stderr: ", a, b, c)
		end,
		on_exit = function(j, return_val)
			table.remove(spawned_processes, j.pid)
			print("on_exit: ", return_val, vim.inspect(j:result()))
		end,
	})
	job:start()

	add_process(job.pid)
end

local function create_buffer()
	local buf_id = vim.api.nvim_create_buf(false, true)
	if buf_id == 0 then
		error("Failed to create buffer")
		return
	end

	return buf_id
end

local function create_win(buf_id)
	vim.api.nvim_open_win(buf_id, true, {
		relative = "editor",
		width = vim.api.nvim_win_get_width(0),
		height = 10,
		row = 0,
		col = 0,
		style = "minimal",
	})
end

local function write_buffer(bufnr, lines, max_lines)
	max_lines = max_lines or 1000
	local opts = { buf = bufnr }

	vim.api.nvim_set_option_value("readonly", false, opts)
	vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, lines)
	local num_lines = #vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
	if num_lines > max_lines then
		vim.api.nvim_buf_set_lines(bufnr, 0, num_lines - max_lines, false, {})
	end
	vim.api.nvim_set_option_value("readonly", true, opts)

	vim.api.nvim_set_option_value("modified", false, opts)
end

create_win(create_buffer())

local function on_done()
	for _, pid in pairs(spawned_processes) do
		vim.system({ "kill", pid }):wait()
	end
end

vim.api.nvim_create_autocmd("VimLeavePre", { callback = on_done })

return M
