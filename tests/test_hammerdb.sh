#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function initdb_pod {
	echo "Setting up a MS-SQL DB Pod"
	kubectl create -f tests/mssql.yaml
        mssql_pod=$(get_pod "app=mssql" 300 "sql-server")
	kubectl wait --for=condition=Ready "pods/$mssql_pod" --namespace sql-server --timeout=300s
}

function finish {
	echo "Cleaning up hammerdb"
	kubectl delete -f tests/mssql.yaml 
	kubectl delete -f tests/test_crs/valid_hammerdb.yaml
	delete_operator
}

trap finish EXIT

function functional_test_hammerdb {
	initdb_pod
	apply_operator
	kubectl apply -f tests/test_crs/valid_hammerdb.yaml
	uuid=$(get_uuid 20)

        wait_for_backpack $uuid
        
	# Wait for the creator pod to initialize the DB
        #DISABLED
	#hammerdb_creator_pod=$(get_pod "app=hammerdb_creator-$uuid" 300)
	#kubectl wait --for=condition=Initialized "pods/$hammerdb_creator_pod" --namespace my-ripsaw --timeout=100s
	#kubectl wait --for=condition=complete -l app=hammerdb_creator-$uuid --namespace my-ripsaw jobs --timeout=600s
	# Wait for the workload pod to run the actual workload
	hammerdb_workload_pod=$(get_pod "app=hammerdb_workload-$uuid" 300)
	kubectl wait --for=condition=Initialized "pods/$hammerdb_workload_pod" --namespace my-ripsaw --timeout=100s
	kubectl wait --for=condition=complete -l app=hammerdb_workload-$uuid --namespace my-ripsaw jobs --timeout=300s
	#kubectl logs "$hammerdb_workload_pod" --namespace my-ripsaw | grep "SEQUENCE COMPLETE"
	kubectl logs "$hammerdb_workload_pod" --namespace my-ripsaw | grep "Timestamp"
	echo "Hammerdb test: Success"
}

functional_test_hammerdb
