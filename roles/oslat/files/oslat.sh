# Adapted from https://github.com/tc-wilson/container-tools
#!/bin/bash

# env vars:
#	RUNTIME (default 5m)
#	DISABLE_CPU_BALANCE
#	USE_TASKSET

DIR=$(dirname "$0")
source ${DIR}/functions.sh

function sigfunc() {
	if [ "${DISABLE_CPU_BALANCE:-n}" == "y" ]; then
		enable_balance
	fi
	exit 0
}

echo "############# dumping env ###########"
env
echo "#####################################"

echo " "
echo "########## container info ###########"
echo "/proc/cmdline:"
cat /proc/cmdline
echo "#####################################"

echo "**** uid: $UID ****"
RUNTIME=${RUNTIME:-5m}

cpulist=`get_allowed_cpuset`
echo "allowed cpu list: ${cpulist}"

uname=`uname -nr`
echo "$uname"

if [[ -z "${RTPRIO}" ]]; then
        RTPRIO=99
elif [[ "${RTPRIO}" =~ ^[0-9]+$ ]]; then
	if (( RTPRIO > 99 )); then
		RTPRIO=99
	fi
else
	RTPRIO=99
fi

# change list seperators from comma to new line and sort it 
cpulist=`convert_number_range ${cpulist} | tr , '\n' | sort -n | uniq`

declare -a cpus
cpus=(${cpulist})

if [ "${DISABLE_CPU_BALANCE}" == "true" ]; then
	disable_balance
fi

trap sigfunc TERM INT SIGUSR1

cyccore=${cpus[1]}
cindex=2
ccount=1
while (( $cindex < ${#cpus[@]} )); do
	cyccore="${cyccore},${cpus[$cindex]}"
	cindex=$(($cindex + 1))
        ccount=$(($ccount + 1))
done

sibling=`cat /sys/devices/system/cpu/cpu${cpus[0]}/topology/thread_siblings_list | awk -F '[-,]' '{print $2}'`
if [[ "${sibling}" =~ ^[0-9]+$ ]]; then
        echo "removing cpu${sibling} from the cpu list because it is a sibling of cpu${cpus[0]} which will be the cpu-main-thread"
        cyccore=${cyccore//,$sibling/}
fi
echo "new cpu list: ${cyccore}"

prefix_cmd=""
if [ "${USE_TASKSET}" == "true" ]; then
	prefix_cmd="taskset --cpu-list ${cyccore}"
fi
 
echo "cmd to run: oslat --runtime ${RUNTIME} --rtprio ${RTPRIO} --cpu-list ${cyccore} --cpu-main-thread ${cpus[0]}"

oslat --runtime ${RUNTIME} --rtprio ${RTPRIO} --cpu-list ${cyccore} --cpu-main-thread ${cpus[0]}

if [ "${DISABLE_CPU_BALANCE}" == "true" ]; then
	enable_balance
fi
