#!/bin/bash
sudo tshark -l -i lo -Y "ip.version == 4 and tcp" -T fields -e tcp.srcport -e tcp.dstport -e tcp.flags.fin -e tcp.flags.reset -e tcp.len -e tcp.flags.str -e frame.time -t a 1>tshark.txt
