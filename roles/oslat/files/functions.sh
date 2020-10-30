# Adapted from https://github.com/jianzzha/container-tools
function convert_number_range() {
        # converts a range of cpus, like "1-3,5" to a list, like "1,2,3,5"
        local cpu_range=$1
        local cpus_list=""
        local cpus=""
        for cpus in `echo "$cpu_range" | sed -e 's/,/ /g'`; do
                if echo "$cpus" | grep -q -- "-"; then
                        cpus=`echo $cpus | sed -e 's/-/ /'`
                        cpus=`seq $cpus | sed -e 's/ /,/g'`
                fi
                for cpu in $cpus; do
                        cpus_list="$cpus_list,$cpu"
                done
        done
        cpus_list=`echo $cpus_list | sed -e 's/^,//'`
        echo "$cpus_list"
}


function get_allowed_cpuset() {
	local cpuset=`cat /proc/self/status | grep Cpus_allowed_list: | cut -f 2`
	echo ${cpuset}
}


function disable_balance()
{
	local cpu=""
	local file=
	local flags_cur=
	for cpu in ${cpulist}; do
		for file in $(find /proc/sys/kernel/sched_domain/cpu$cpu -name flags -print); do
			flags_cur=$(cat $file)
			flags_cur=$((flags_cur & 0xfffe))
			echo $flags_cur > $file
		done
	done
}


function enable_balance()
{
	local cpu=""
	local file=
	local flags_cur=
	for cpu in ${cpulist}; do
		for file in $(find /proc/sys/kernel/sched_domain/cpu$cpu -name flags -print); do
			flags_cur=$(cat $file)
			flags_cur=$((flags_cur | 0x1))
			echo $flags_cur > $file
		done
	done
}
