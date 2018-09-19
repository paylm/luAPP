local redis = require "resty.redis"
ngxmatch=ngx.re.find
local url = ngx.var.request_uri
local server_name  = ngx.var.server_name
local version = 1

function redis_conn()
	local cache = redis.new()
	cache:set_timeout(5000)

	local ok, err = cache.connect(cache, '127.0.0.1', 6380)
	if not ok then
		return
	end
	local count, err = cache:get_reused_times()
	if 0 == count then
		local red, err = cache:auth("xxxxxx")
		if not red then
			return
		end	  
		cache:select(tonumber('5'))
	end

	return cache
end

local cache = redis_conn()

function savePostToRds()
	ngx.req.read_body()
	local post_body = ngx.req.get_body_data()
	if not post_body then
		--ngx.log(ngx.ERR,"savePostRds read body is nil")
		return 
	end
	---ngx.log(ngx.ERR,post_body)
	msg = "{'@version':'"..version.."','host':'"..server_name."','url':'"..url.."','data':'"..post_body.."'}"
	--ngx.log(ngx.ERR,msg)
	cache:publish("elk_body",msg)
end

savePostToRds()


local ok, err = cache:set_keepalive(10000, 100)
if not ok then
	ngx.log(ngx.ERR,"inner failed to set keepalive: ", err)
	return
end

---测试方法订阅redis管道:PSUBSCRIBE elk_*
--- nginx setting
--- server setting 
--- server {
---    lua_need_request_body on;
---      location/ {
---	          mirror /mirror_tonc;
 ---           mirror_request_body on;
 ---           #root           /webroot;
 ---          }
---	location /mirror_tonc {
---		internal;
---		proxy_set_header Content-Length "";
--- 		proxy_set_header X-Original-URI $request_uri;
---		#proxy_pass http://127.0.0.1:999$request_uri;
---		#proxy_pass http://172.20.200.170:12345$request_uri;
---		content_by_lua_file conf/lua/mirror_redis.lua;
---	}
---}
