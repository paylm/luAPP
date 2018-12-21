#!/bin/bash

# 执行脚本机器需要装redis-cli
# description:导出redis 所有key 到 redis_data.zip 的压缩包中
# 还原方法: 把redis_data.zip 和脚本都复制目标机器上,执行: sh rds.sh xxx.xxx.xxx.xxx port db passwd restore

server=${1:-127.0.0.1}
port=${2:-6379}
db=${3:-1}
passwd=$4
action=$5
output_data="redis_data"

mkdir -p ${output_data}

cmd="redis-cli -h ${server} -p ${port} -n ${db} --raw"
if [ ! -z ${passwd} ];then
	cmd="redis-cli -h ${server} -p ${port} -n ${db} -a ${passwd} --raw"
fi


keys=$($cmd keys '*')

function backup(){
    #dump cmd :redis-cli -p 6379 -n 1 -a kingdee --raw dump limit1
    rm -rf ${output_data}/* 
    for k in $keys;do
    	#init
    	$cmd dump $k > 	${output_data}/$k
    done
    zip -r ${output_data}.zip ${output_data}
    echo "all the key has dump to ${output_data}"
}

function restore(){
        rm -f ${output_data}/*
        unzip ${output_data}.zip 
	for i in `ls ${output_data}`;do
		cat ${output_data}/$i |head -c -1 | $cmd -x restore $i 0
	done
	echo "所有数据已恢复到$db中"
}

if [ ! -z ${action} -a ${action} == "restore" ];then
   restore
else
   backup
fi
