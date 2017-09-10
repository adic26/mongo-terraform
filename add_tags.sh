#!/usr/bin/env bash

if [ $# -ne 3 ]
then
  #echo "Expected 3 arguements [Name, owner, expire-on]"
  #exit 1
  name=terratest
  owner=mark.baker-munton
  expire=2010-01-01
else
  name=$1
  owner=$2
  expire=$3
fi

instance_ids=`terraform output -module=mongod instance_ids`
counter=1
for id in $instance_ids
do
	aws ec2 create-tags --resources $id --tags Key=Name,Value=$name-$counter Key=owner,Value=$owner Key=expire-on,Value=$expire
	((counter++))
done

echo "added tags for ["`echo $instance_ids | tr -d \n`"]"