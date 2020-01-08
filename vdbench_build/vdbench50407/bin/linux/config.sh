#!/bin/bash

#
# Copyright (c) 2000, 2013, Oracle and/or its affiliates. All rights reserved.
#

#
# Author: Henk Vandenbergh.
#



echo `date`;echo ">>>>>uname -a"
uname -a

echo `date`;echo ">>>>>ifconfig -a"
ifconfig -a

echo `date`;echo ">>>>>id"
id

echo `date`;echo ">>>>>mount"
mount

echo `date`;echo ">>>>>memory"
cat /proc/meminfo
free -l

# Show if there are any other vdbench tests running:
echo `date`;echo ">>>>>ps -ef | grep -i vdb"
ps -ef | grep -i vdb

