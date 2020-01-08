#!/bin/sh


BASE_DIR=/opt/vdbench
RUN_DIR=$BASE_DIR}/bin
TEMPLATE_PATH=${BASE_DIR}/conf
TEST_TEMPLATES=Standard
TEST_DURATION=600

if [ $# -gt 0 ];
then
  echo "Setting the test ${BASE_DIR} as $1"
  TEST_TEMPLATES=$1
  if [ ! -d "${TEMPLATE_PATH}/$TEST_TEMPLATES" ]; then
    echo "Specified ${TEMPLATE_PATH}$TEST_TEMPLATES do not exist."
    exit 1
  fi
fi

if [ $# -gt 1 ];
then
  echo "Setting the duration for tests as $2"
  TEST_DURATION=$2
fi

#Verify that the lun0 used by the ${BASE_DIR} is mounted
df -h -P | grep -q lun0
if [ `echo $?` -ne 0 ]; then
  echo -e "lun0 not mounted successfully, exiting \n"
  exit
else
  echo "lun0 mounted successfully"
fi

# Use this to update the size of the volume
for i in `ls ${TEMPLATE_PATH}/${TEST_TEMPLATES}/File*`; do 
  sed -e "s|elapsed=600|elapsed=$TEST_DURATION|g" -i $i 
done

# Start vdbench I/O iterating through each template file
timestamp=`date +%d%m%Y_%H%M%S`
echo -e "Running $TEST_TEMPLATES Workloads\n"
pwd
id

for i in `ls ${TEMPLATE_PATH}/${TEST_TEMPLATES}/ | cut -d "/" -f 3`
do
 echo "######## Starting workload -- $i#######"
 ${RUN_DIR}/vdbench -f ${TEMPLATE_PATH}/${TEST_TEMPLATES}/$i -o ${BASE_DIR}/outputs/$i-$timestamp | tee -a ${BASE_DIR}/logs/${i}.log
 echo "######## Ended workload -- $i#######"
done

