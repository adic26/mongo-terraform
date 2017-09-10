#!/usr/bin/env bash

if [ $# -eq 0 ]
then
  echo "No arguments supplied!"
  exit 1
fi

filename=private_ips

terraform output -module=mongod private_ips > $filename

sed -i -e 's/,//g' $filename

counter=0
while read p; do 
  if [ $counter -eq 0 ]
  then
    members="{ _id: $counter, host: \"$p\", priority: 2 }"
  else
    members=$members",{ _id: $counter, host: \"$p\" }"
  fi
  
  ((counter++))
done < $filename

rs_config=`echo "
   {
      _id: \"$1\",
      version: 1,
      members: [
         $members
      ]
   }"`
   
reconfig="rs.reconfig($rs_config)"

rs_config_escaped=`echo $reconfig | sed -e 's/(/\\(/g' | sed -e 's/)/\\)/g'`

echo $rs_config_escaped

./aws-ssh.sh 1 "$rs_config_escaped"