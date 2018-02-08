#!/usr/bin/env bash

counter=0

if [ $# -eq 0 ]
then
  echo "No arguments supplied!"
  exit 1
fi

if [ $# -lt 2 ]
then
  echo "No hosts supplied!"
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

mongo --eval "rs.initiate($rs_config)"