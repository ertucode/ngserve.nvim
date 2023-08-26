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

local function on_done()
	for _, pid in pairs(spawned_processes) do
		vim.system({ "kill", pid }):wait()
	end
end

vim.api.nvim_create_autocmd("VimLeavePre", { callback = on_done })

return M
