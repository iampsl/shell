#!/usr/bin/sh

#查看子进程是否还存在
# isChildExist ppid pid 
function isChildExist(){
	if [ $# -ne 2 ];then
		echo "useage: isChildExist ppid pid"
		echo " arguments error:$*"
		return 1
	fi
	local parentid=$(ps -o ppid= "${2}" | xargs)
	if [ "$parentid" = "${1}" ];then
		return 0
	fi
	return 2
}

#向指定子进程广播信号
#broadcast signal ppid pid...
function broadcast(){
	if [ $# -lt 3 ];then
		echo "usage: broadcast signal ppid pid..."
		echo "arguments error:$*"
		return 0
	fi
	local sig="${1}"
	local parent="${2}"
	shift 2
	while [ $# -gt 0 ];do
		isChildExist "${parent}" "${1}"
		if [ $? -eq 0 ];then
			kill -s "${sig}" "${1}"
		fi
		shift
	done
	return 0
}



#申明错误码
declare -r ErrStart=1 #启动方式不对

if [ $# -ne 2 ];then
	echo "useage:cmdstring systemd"
	exit $ErrStart
fi

if [ "$2" != "systemd" ];then
	echo "you should start by systemd"
	exit $ErrStart
fi

#当前进程id
parentpid=$$
#子进程id
${1} &
childpid=$!

function onSigTerm(){
	echo "on sigterm"
	broadcast SIGTERM ${parentpid} ${childpid}
}

trap onSigTerm SIGTERM

shouldstop="no"

while [ "${shouldstop}" = "no" ];do
	sleep 2
	isChildExist ${parentpid} ${childpid}
	if [ $? -ne 0 ];then
		wait ${childpid}
		if [ $? -eq 0 ];then
			shouldstop="yes"
		else
			${1} &
			childpid=$!
		fi
	fi
done
exit 0






