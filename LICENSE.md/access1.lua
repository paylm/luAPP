
-- definde http get()
function get(ip,cookie,url)
    --ngx.say("curl -H 'remote_req_ip:"..ip.."' --cookie '"..cookie.."' -I -m 10 -o /dev/null -s -w %{http_code} '"..url.."'")
    ngx.log(ngx.ERR, "get : ", "curl -H 'remote_req_ip:"..ip.."' --cookie '"..cookie.."' -I -m 10 -o /dev/null -s -w %{http_code} '"..url.."'")
    local handle = io.popen("curl -H 'remote_req_ip:"..ip.."' --cookie '"..cookie.."' -I -m 10 -o /dev/null -s -w %{http_code} '"..url.."'")
    local result = handle:read("*a")
    handle:close()
    return result
end

--define split word
function split(s, delim)
  if type(delim) ~= "string" or string.len(delim) <= 0 then
    return
  end

  local start = 1
  local t = {}
  while true do
  local pos = string.find (s, delim, start, true) -- plain find
    if not pos then
     break
    end

    table.insert (t, string.sub (s, start, pos - 1))
    start = pos + string.len (delim)
  end
  table.insert (t, string.sub (s, start))

  return t
end

-- remote real ip
local headers=ngx.req.get_headers()
local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"

ck = ngx.var.http_cookie

if not ck then
   ngx.say("please login")
   ngx.exit(ngx.HTTP_BAD_REQUEST)
   return 
end

ls = split(ck,";")
--print(#ls)
for i=1,#ls do
    if string.find(ls[i],"sid") ~= nil then
         --print("good job")
         ck=ls[i]..";"
         break
    end
end
         --

local config = ngx.shared.config
--ngx.say(ck)
local oip = config:get(ck) --old remote_req_ip
if oip ~= nil and oip == ip then 
   --ngx.say("local from cache")   
   return true
end

--to bankend check login
rtcode = get(ip,ck,"http://erpcloud.kingdee.com/index.php?m=my&f=index")

--ngx.say(rtcode)

if '200' ~= rtcode then
	ngx.say("no auth")
	ngx.exit(ngx.HTTP_BAD_REQUEST)
	return 302
end

--ngx.say("login ok")
-- save 4 h 
config:safe_set(ck,ip,14400) 
return true
