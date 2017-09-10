#!/usr/bin/env bash

if [ $# -eq 0 ]
then
  echo "Which server to connect to? Give me a number."
  exit 1
fi

if [ $1 -eq "0" ]
then
  echo "Servers are not zero-indexed. (Use 1 for the first server)"
  exit 1
fi

terraform output public_ips > public_ips

sed -i -e 's/,//g' public_ips

IP=`sed -e "$1q;d" public_ips`

echo "ssh -i ~/.ssh/markbm.pem ec2-user@$IP $2"

ssh -i ~/.ssh/markbm.pem ec2-user@$IP "$2"
