#!/bin/bash
#do any kind of prelim setup/update binary with compiled version, etc
echo Doing $@.....
#should be configured to kill old versions of the test
./setup 
echo Setup done
if ! pgrep -x "tshark" >/dev/null
then 
	echo tshark not running, exiting
	exit
fi
echo "Start test "$@" || $(date "+%s")">>mainLog.txt
echo Starting test

log_file=$1
shift

echo Starting server
./server "$@" &
#listens on port 31004
echo Starting servermitm
python3 mitm.py -i 31003 -o 31004 -F serverProxyMITM.txt &
#passes serverProxy (31003) -> Server (31004)
echo Starting serverproxy
./server-proxy >serverProxy.txt &
#should be configured to listen on port 10086, and connect to 31003 (if needed, typically determined by the client)


echo Starting mitm
python3 mitm.py -i 31002 -o 10086 -F mainMITM.txt  "$@"  &
#passes client proxy (pointing to 31002) to server proxy (listening on 10086)
echo Starting clientProxy
./client-proxy >clientProxy.txt &
#should be listening on 31001, connecting to 31002
echo Starting Clientproxymitm
python3 mitm.py -i 31000 -o 31001 -F clientProxyMITM.txt &
#passes client (not listening) -> client proxy (listening on 31001)

sleep 2
#waiting for mitms to spin up
echo Spawning client
./client "$@"
sleep 2
python3 extractFin.py -f

echo "Results:" >> $log_file
echo "clientProxyMITM:" >> $log_file
cat clientProxyMITM.txt >> $log_file
echo "mainMITM:" >> $log_file
cat mainMITM.txt >> $log_file
echo "serverProxyMITM:" >> $log_file
cat serverProxyMITM.txt >> $log_file
echo "Client:" >> $log_file
cat client.txt >> $log_file
echo "Server:" >> $log_file
cat server.txt >> $log_file

rm *.txt
