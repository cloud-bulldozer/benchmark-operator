#!/bin/bash

#inc_f="/tmp/include_disk"
inc_f="/tmp/host_list"
>${inc_f}

cfg_file="/tmp/vdbench/vdbenchjob-test_defenition"

bdir="/opt/vdbench"

echo "host=default,vdbench=/opt/vdbench/bin,user=root,shell=vdbench" >> ${inc_f}

index=0
for host in `cat /tmp/host/hosts`
do
  echo "hd=hd${index},system=${host}" >> ${inc_f}
  ((index=$index+1))
done

${bdir}/bin/vdbench -f ${cfg_file} -o  ${bdir}/outputs/TestRun | tee ${bdir}/logs/TestRun.log
${bdir}/scripts/make_report.py ${bdir}/logs/TestRun.log
tar -cf /tmp/Results.tar ${bdir}/outputs/* ${bdir}/logs/*
gzip /tmp/Results.tar

exit 0

for i in `seq 0 $(($index-1))`
do
  echo "fsd=fsd${i},anchor=/mnt/pvc/dir${i},depth=${VD_DEPTH},width=${VD_WIDTH},files=${VD_FILES},size=${VD_SIZE}M" >> ${inc_f}
done

for i in `seq 0 $(($index-1))`
do
  echo "fwd=rr_${i},host=hd${i},fsd=fsd${i},operation=read,xfersize=4k,fileio=random,fileselect=random,threads=8" >> ${inc_f}
done

for i in `seq 0 $(($index-1))`
do
  echo "fwd=rw_${i},host=hd${i},fsd=fsd${i},operation=write,xfersize=4k,fileio=random,fileselect=random,threads=8" >> ${inc_f}
done

for i in `seq 0 $(($index-1))`
do
  echo "fwd=rm_${i},host=hd${i},fsd=fsd${i},operation=write,rdpct=75,xfersize=4k,fileio=random,fileselect=random,threads=8" >> ${inc_f}
done

 echo "rd=RandomRead,fwd=rr_*,fwdrate=max,format=yes,elapsed=${VD_RUNTIME},interval=10,pause=1m" >> ${inc_f}
 echo "rd=RandomWrite,fwd=rw_*,fwdrate=max,format=no,elapsed=${VD_RUNTIME},interval=10,pause=1m" >> ${inc_f}
 echo "rd=RandomMix75,fwd=rm_*,fwdrate=max,format=no,elapsed=${VD_RUNTIME},interval=10,pause=1m" >> ${inc_f}

