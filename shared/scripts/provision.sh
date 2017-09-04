#!/usr/bin/env bash

yum -y update
yum -y install deltarpm
yum -y install openssl net-snmp net-snmp-utils cyrus-sasl cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain
