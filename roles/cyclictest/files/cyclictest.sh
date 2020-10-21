# Adapted from https://github.com/jianzzha/container-tools
#!/bin/bash

# env vars:
#	DURATION (default "5m")
#	DISABLE_CPU_BALANCE
#	stress_ng (default "false", or stress-ng)
#	rt_priority (default "99")

DIR=$(dirname "$0")
source ${DIR}/functions.sh

function sigfunc() {
        tmux kill-session -t stress 2>/dev/null
	if [ "${DISABLE_CPU_BALANCE}" == "true" ]; then
		enable_balance
	fi
	exit 0
}

echo "############# dumping env ###########"
env
echo "#####################################"

echo "**** uid: $UID ****"
if [[ -z "${DURATION}" ]]; then
	DURATION="5m"
fi

if [[ -z "${stressng}" || "${stressng}" == "false" ]]; then
	stress="false"
elif [[ "${stressng}" == "true" ]]; then
	stress="stress-ng"
fi

if [[ -z "${rt_priority}" ]]; then
        rt_priority=99
elif [[ "${rt_priority}" =~ ^[0-9]+$ ]]; then
	if (( rt_priority > 99 )); then
		rt_priority=99
	fi
else
	rt_priority=99
fi

release=$(cat /etc/os-release | sed -n -r 's/VERSION_ID="(.).*/\1/p')

for cmd in tmux cyclictest; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd required but not installed. Aborting"; exit 1; }
done

cpulist=`get_allowed_cpuset`
echo "allowed cpu list: ${cpulist}"

cpulist=`convert_number_range ${cpulist} | tr , '\n' | sort -n | uniq`

declare -a cpus
cpus=(${cpulist})

if [ "${DISABLE_CPU_BALANCE}" == "true" ]; then
	disable_balance
fi

trap sigfunc TERM INT SIGUSR1

# stress run in each tmux window per cpu
if [[ "$stress" == "stress-ng" ]]; then
    yum install -y stress-ng 2>&1 || { echo >&2 "stress-ng required but install failed. Aborting"; sleep infinity; }
    tmux new-session -s stress -d
    for w in $(seq 1 ${#cpus[@]}); do
        tmux new-window -t stress -n $w "taskset -c ${cpus[$(($w-1))]} stress-ng --cpu 1 --cpu-load 100 --cpu-method loop"
    done
fi

if [[ "$stress" == "rteval" ]]; then
	tmux new-session -s stress -d "rteval -v --onlyload"
fi

cyccore=${cpus[0]}
cindex=1
ccount=1
while (( $cindex < ${#cpus[@]} )); do
	cyccore="${cyccore},${cpus[$cindex]}"
	cindex=$(($cindex + 1))
        ccount=$(($ccount + 1))
done

extra_opt=""
if [[ "$release" = "7" ]]; then
    extra_opt="${extra_opt} -n"
fi

echo "running cmd: cyclictest -q -D ${DURATION} -p ${rt_priority} -t ${ccount} -a ${cyccore} -h 30 -m ${extra_opt}"
if [ "${manual:-n}" == "n" ]; then
    cyclictest -q -D ${DURATION} -p ${rt_priority} -t ${ccount} -a ${cyccore} -h 30 -m ${extra_opt}
else
    sleep infinity
fi

# kill stress before exit 
tmux kill-session -t stress 2>/dev/null

if [ "${DISABLE_CPU_BALANCE}" == "true" ]; then
	enable_balance
fi

