#!/bin/bash

''':'
vers=( /usr/bin/python[2-3] )
latest="${vers[$((${#vers[@]} - 1))]}"
if !(ls $latest &>/dev/null); then
    echo "no python present"
    exit 1
fi
cat <<'# EOF' | exec $latest - "$@"
''' #'''
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
import sys

def generate_config(instances):
    config = {'_id': 'rs0'}
    members_list = []
    for i in range(instances):
        mongo_instance = 'mongo-'+str(i)+'.mongo'
        members_list.append({'_id': i, 'host': mongo_instance})
    config['members'] = members_list
    return config

def main():
    if len(sys.argv) < 2:
        sys.exit("usage: initiate_rs.py [number_of_replicas]")
    replicas = int(sys.argv[1])
    c = MongoClient('mongo-0.mongo', 27017)
    c.admin.command("replSetInitiate", generate_config(replicas))
    client = MongoClient('mongo', replicaset='rs0')
    try:
        # The ismaster command is cheap and does not require auth.
        client.admin.command('ismaster')
    except ConnectionFailure:
        print("Server not available")
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
# EOF
