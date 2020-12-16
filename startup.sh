#!/bin/bash

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


#等待直到任一子进程退出
#waitChilds ppid pid...
function waitChilds(){
	if [ $# -lt 2 ];then
		echo "usage: waitChilds ppid pid..."
		echo "arguments error:$*"
		return 0
	fi
	local arguments=("${1}" "${2}")
	shift 2
	while [ $# -gt 0 ];do
		arguments=("${arguments[@]}" "${1}")
		shift
	done
	local index=1
	local total=${#arguments[@]}
	local shouldstop="no"
	local sleepid=0
	while [ "$shouldstop" = "no" ];do
		sleep 5 &
		sleepid=$!
		wait $sleepid
		for (( index=1; index<total; index++ ));do 
			isChildExist "${arguments[0]}" "${arguments[$index]}"
			if [ $? -ne 0  ]; then
				shouldstop="yes"
			fi
		done
	done
}


#kill所有子进程
#killChildren ppid pid...
function killChildren(){
	if [ $# -lt 2 ];then
		echo "usage: killChildren ppid pid..."
		echo "arguments error:$*"
		return 0
	fi
	local parent="${1}"
	shift
	while [ $# -gt 0 ];do
		isChildExist "${parent}" "${1}"
		if [ $? -eq 0 ];then
			kill -s SIGKILL "${1}"
		fi
		shift
	done
	return 0
}

#申明错误码
declare -r ErrStart=1 #启动方式不对

if [ $# -lt 1 ];then
	echo "you should start by systemd"
	exit $ErrStart
fi

if [ "$1" != "systemd" ];then
	echo "you should start by systemd"
	exit $ErrStart
fi

#当前进程id
curpid=$$

#子进程数组
declare -a childs

#启动子进程

sleep 1000 &
childs=("${childs[@]}" $!)

############################

if [ ${#childs[@]} -le 0 ];then
	echo "no children"
	exit 0
fi

trap "{ broadcast SIGTERM ${curpid} ${childs[@]}; }" SIGTERM 

waitChilds ${curpid} ${childs[@]}
sleep 5
killChildren ${curpid} ${childs[@]}
exit 0
