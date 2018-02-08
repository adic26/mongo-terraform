#!/usr/bin/env bash

# Helper for running Javascript snippets in MongoDB.
function mongo_eval() {
  local host=$1
  local cmd=$2
  mongo --quiet --host $host --eval "$cmd"
}

counter=0

if [ $# -eq 0 ]
then
  echo "No arguments supplied!"
  exit 1
fi

if [ $# -lt 2 ]
then
  echo "No members supplied!"
  exit 1
fi

for host in "${@:2}"
do
  if [ $counter -eq 0 ]
  then
    members="{ _id: $counter, host: \"$host\", priority: 2 }"
  else
    members=$members",{ _id: $counter, host: \"$host\" }"
  fi
  
  while true; do
    echo "waiting for response from mongo on $host..."
    count=`mongo_eval $host 'printjson(db.runCommand("ping"))' 2>/dev/null | grep '"ok" : 1' | wc -l`
    [ $count -eq 1 ] && break
    sleep 2
  done  
  
  ((counter++))
done
 
rs_config=`echo "
   {
      _id: \"$1\",
      version: 1,
      members: [
         $members
      ]
   }"`

output=`mongo --eval "rs.initiate($rs_config)"`
echo $output

success=`echo $output | grep '"ok" : 1' | wc -l`

if [ "$success" != "1" ]; then
  echo "failed to initiate replica set"
  exit 1;
else
  echo "replica set initiated!"
fi