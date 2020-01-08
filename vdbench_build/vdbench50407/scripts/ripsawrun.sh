#!/bin/bash

# This scrips is design to run the vdbench test in container that create with the Ripsaw operator.
#
# It create file that contain the list of hosts which will use in the test, then it will run the
# configuration file created by the operator. when the benchmark run is finished, it will run the
# script that create excel report from the results, collect all outputs, logs and results into
# tar file.
#
# Author : Avi Liani <alayani@redhat.com>
# Date : Dec. 26, 2019

# Base dir path
bdir="/opt/vdbench"

# The includ file for the test
inc_f="/tmp/host_list"

# The test configuration file
cfg_file="/tmp/vdbench/vdbenchjob-test_defenition"

# Default host configuration for the test
echo "hd=default,vdbench=/opt/vdbench/bin,user=root,shell=vdbench" > ${inc_f}

index=0
# Add each host (IP) that will used inthe test to the include file
for host in `cat /tmp/host/hosts`
do
  echo "hd=hd${index},system=${host}" >> ${inc_f}
  ((index=$index+1))
done

# Run The test
${bdir}/bin/vdbench -f ${cfg_file} -o  ${bdir}/outputs/TestRun | tee ${bdir}/logs/TestRun.log

# Generate the report
${bdir}/scripts/make_report.py ${bdir}/logs/TestRun.log

# Collect all outputs to tar.gz file
tar -cf /tmp/Results.tar ${bdir}/outputs/* ${bdir}/logs/*
gzip /tmp/Results.tar
