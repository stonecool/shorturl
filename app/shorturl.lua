local json = require('cjson')

local storage = require('storage')
local config = require('config')


-- 获取当前请求的HTTP请求方法名
local method = ngx.req.get_method()
if 'POST' ~= method then
	return ngx.exit(ngx.HTTP_NOT_ALLOWED)
end

-- 同步读取客户端请求体，不阻塞 Nginx 事件循环
ngx.req.read_body()

-- 取回内存中的请求体数据。本函数返回 Lua 字符串而不是包含解析过参数的 Lua table
body = ngx.req.get_body_data()


local function validator(body)
	local ok, data = pcall(json.decode, body)
	if not ok then
		return nil, 200, '数据格式错误'
	end

	local url = data.url or ''

	-- 正则验证url
	local regex = [[https?:/{2}\w.+$]]
	local m, err = ngx.re.match(url, regex, "jo")
	if not m then
		return nil, 10002, 'url格式错误'
	end

	return data, nil, nil
end


local res, code, err = validator(body)

-- 修改、添加、或清除当前请求待发送的 HEADER 响应头信息。
ngx.header['Content-Type'] = 'application/json; charset=utf-8'

if res then
	local key = storage:set(res.url)

	ngx.say(json.encode({
		result = true,
		resultcode = 200,
		msg = '',
		errormsg = '',
		data = {
			url = config.url .. key
		}
	}))
else
	ngx.say(json.encode({
		result = false,
		resultcode = code,
		msg = '',
		errormsg = '',
		data = {}
	}))
end
