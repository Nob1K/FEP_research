#!/bin/bash
wait_for_port() {
  local host=$1
  local port=$2
  local timeout=${3:-10}
  python3 -c "
import socket, time
deadline = time.time() + $timeout
while time.time() < deadline:
    try:
        with socket.create_connection((\"$host\", $port), timeout=0.5):
            exit(0)
    except:
        time.sleep(0.1)
exit(1)
"
}
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
#listens on port 31004
./server "$@" &
echo Starting servermitm
#passes serverProxy (31003) -> Server (31004)
python3 mitm.py -i 31003 -o 31004 -F serverProxyMITM.txt &
echo Starting serverproxy
#should be configured to listen on port 10086, and connect to 31003 (if needed, typically determined by the client)
./server-proxy-obfs4 >serverProxy.txt &
wait_for_port 127.0.0.1 10086 || {
  echo "Server proxy did not start in time"; exit 1;
}


echo Starting mitm
#passes client proxy (pointing to 31002) to server proxy (listening on 10086)
python3 mitm.py -i 31002 -o 10086 -F mainMITM.txt  "$@"  &
echo Starting clientProxy
#should be listening on 31001, connecting to 31002
./client-proxy-obfs4 >clientProxy.txt &
wait_for_port 127.0.0.1 31001 || {
  echo "Client proxy did not start in time"; exit 1;
}
echo Starting Clientproxymitm
#passes client (not listening) -> client proxy (listening on 31001)
python3 mitm.py -i 31000 -o 31001 -F clientProxyMITM.txt &


sleep 2
#waiting for mitms to spin up
echo Spawning client
./client "$@"
sleep 2

echo "Results extracted:" >> $log_file
python3 extractFin.py -f >> $log_file
echo -e "\nclientProxyMITM:" >> $log_file
cat clientProxyMITM.txt >> $log_file
echo -e "\nmainMITM:" >> $log_file
cat mainMITM.txt >> $log_file
echo -e "\nserverProxyMITM:" >> $log_file
cat serverProxyMITM.txt >> $log_file
echo -e "\nClient:" >> $log_file
cat client.txt >> $log_file
echo -e "\nServer:" >> $log_file
cat server.txt >> $log_file

for file in *.txt; do
  [ "$file" != "tshark.txt" ] && rm "$file"
done
