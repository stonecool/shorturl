# OpenResty shorturl

基于OpenResty实现短地址生成服务
- 使用Redis存储
- 数据落地到MySQL采用基于Redis的[MQ](https://github.com/stonecool/messagequeue)

```Shell
	curl -X POST \
	http://127.0.0.1:7788/api/shorturl.json \
	-H 'content-type: Application/json' \
	-d '{
		"url":"http://github.com"
	}'
```

### 致谢
- [基于openresty实现的短网址服务](https://github.com/zhu327/shorturl)
