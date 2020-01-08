
*
* Copyright (c) 2000, 2012, Oracle and/or its affiliates. All rights reserved.
*

*
* Author: Henk Vandenbergh.
*

The Vdbench example parameter files are contained in two subdirectories:
- raw:     For doing raw i/o against whole volumes or large files
           This uses SD, WD, and RD parameters
- filesys: For file system testing.
           This uses FSD, FWD and RD parameters

(There is also a sample 'errorlog.html' file for demonstration purposes
to be used with the new ./vdbench dvpost Data validation Posp Porcessing function)


Parameter files in the 'raw' directory can be easily changed to accomodate
running against multiple volumes. Just add extra Storage Definition (SD)
parameters, e.g. sd=sd2,lun=cxtxdxsx

Parameter files in the 'raw' directory can be easily changed to accomodate
using large files by replacing the 'lun=' name to a real file name.
If the file name does not exist AND a size= is specified, Vdbench will
create this file and then preformats it.
e.g. sd=sd1,lun=/dir/large_file,size=100m
To influence the way that the file systems handle caching for these files,
look in vdbench.pdf for 'openflags='


Parameter files can also be changed for tape processing.
e.g. sd=sd1,lun=/dev/rmt/0,size=500g

Note: a maximum size for a tape must be specified (size=)
Note: a read will only be done for a tape written in the same vdbench execution.
This is done so that vdbench knows when to expect EOT.
