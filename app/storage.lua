local redis = require('redis_db')
local mysql = require('mysql_db')
local json = require('cjson')

local config = require('config')


function convert_to_code(num)
	local codes = "QKV4hy7YaBMgWUzFAJLpPudeoGHnOi0m6xItDj2cRE8Cwq1s9rblXTSkvN3f5Z"
	local str = ""
	local length = string.len(codes)
	local index, char

	while num > 0 do
		index = math.fmod(num, length) + 1
		char = string.sub(codes, index, index)
		str = char .. str

		num = math.floor(num / length)
	end

	return str
end


-- 与 redis 相关
function setKVtoRedis(key, value)	
	local red = redis:new(config.redis)
	local res, err = red:set(key, value)	

	if res then
		ngx.log(ngx.DEBUG, 'redis set key: ' .. key .. ': ' .. value)
	else
		ngx.log(ngx.ERR, 'redis connection error')
	end
end


function getValueByKeyFromRedis(rKey)
	local red = redis:new(config.redis)

	local res, err = red:get(rKey)
	if not res then
		ngx.log(ngx.ERR, 'redis connection error')
	end

	return res
end


function pushKVtoList(key, value)
		local tab = {
			key = key,
			url = value,
			time = ngx.now()
		}
		local str = json.encode(tab)
		local red = redis:new(config.redis)

		res, err = red:rpush('shorturl_list', str)
		if res then
			ngx.log(ngx.DEBUG, 'redis push list key: ' .. key)
				
			res, err = red:publish('shorturl_channel', '')
			if res then
				ngx.log(ngx.DEBUG, "redis publish ok")
			else
				ngx.log(ngx.ERR, "redis publish error")
			end
		else
			ngx.log(ngx.ERR, 'redis connection error')
		end

end


function initRedis(initKey)
	local red = redis:new(config.redis)
	local res, err = red:get(initKey)

	if not res then
		res, err = red:set(initKey, 12345678)
		if not res then
			ngx.log(ngx.ERR, 'redis connection error')
		else
			ngx.log(ngx.DEBUG, 'redis set value ' .. tostring(res))
		end
	end

end


function get_next_index(indexKey)
	local red = redis:new(config.redis)
	local res, err = red:incr(indexKey)
	
	if not res then
		ngx.log(ngx.ERR, 'redis connection error')
	else
		ngx.log(ngx.DEBUG, 'redis incr' .. tostring(res))
	end

	return res
end

-- 与 mysql 相关 
function getValueByKeyFromMysql(key)
	local db = mysql:new(config.mysql)
	local sql = "SELECT `value` FROM `t_shorturl` WHERE `key` = ? LIMIT 1"
	local res, err, errno, sqlstate = db:select(sql, {key})

	if not res or err then
		ngx.log(ngx.ERR, "mysql select failed: " .. tostring(err))
	elseif res[1] then
		return res[1].value
	end
end

local _M = {
	_index_key = "shorturl::_index::",
	_base_key  = "shorturl::_base::"
}

function _M:init()
	initRedis(self._index_key)
end


function _M:getRedisKey(key)
	return self._base_key .. key
end


function _M:set(url)
	local nextIndex = get_next_index(self._index_key)
	local key = convert_to_code(nextIndex)
	local rKey = self:getRedisKey(key)

	setKVtoRedis(rKey, url)
	pushKVtoList(key, url)

	return key
end


function _M:get(key)
	local rKey = self:getRedisKey(key)
	local value  = getValueByKeyFromRedis(rKey)
	if not value then
		value = getValueByKeyFromMysql(key)
	 	if value then
			setKVtoRedis(rKey, value)
			ngx.log(ngx.DEBUG, 'mysql get key: ' .. key .. ': ' .. tostring(value))
		else
			ngx.log(ngx.ERR, 'no value found by key: ' .. tostring(key))
		end
	else
		ngx.log(ngx.DEBUG, 'redis get key: ' .. key .. ': ' .. tostring(value))
	end

	return value
end


return _M
