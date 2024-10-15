#!/bin/bash

# parse the arguments
for i in "$@"; do
  case $i in
    --transparent-type=*)
      TYPE="${i#*=}"
      shift
      ;;
    --stage=*)
      STAGE="${i#*=}"
      shift
      ;;
    -*|--*)
      shift
      ;;
    *)
      ;;
  esac
done


case "$STAGE" in
post-start)
  # at the post-start stage
  # we first check the $TYPE so we know which table should we insert into
  if [ "$TYPE" = "tproxy" ]; then
    TABLE=mangle
    POS=3
  elif [ "$TYPE" = "redirect" ]; then
    TABLE=nat
    POS=1
  else
    echo "unexpected transparent type: ${TYPE}"
    exit 1
  fi
  # print what we are excuting and exit if it fails
  set -ex
  # insert the iptables rules for ipv4
  iptables -t "$TABLE" -I TP_RULE "$POS" -s 192.168.8.102/32, 192.168.8.108/32, 192.168.8.110/32, 192.168.8.115/32, 192.168.8.150/32, 192.168.8.118/32, 192.168.8.123/32, 192.168.8.127/32, 192.168.8.128/32 -j RETURN
  ;;
pre-stop)
  # we do nothing here because the TP_RULE chain will be flushed automatically by v2rayA.
  # we can also do it manually.
  ;;
*)
  ;;
esac

exit 0