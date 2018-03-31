local storage = require('storage')


-- 返回当前 Nginx 工作进程的一个顺序数字（从 0 开始）。
-- 所以，如果工作进程总数是 N，那么该方法将返回 0 和 N - 1 （包含）的一个数字。
local workerId = ngx.worker.id()
if 0 == workerId then
	local ok, err = ngx.timer.at(0, function(premature)
		storage:init()
	end)

	if not ok then
		ngx.log(ngx.ERR, "failed to create the timer: ", err)
		return os.exit(1)
	end
end

