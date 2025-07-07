import socketserver,threading,datetime,socket,select,time,os,argparse,string
outAddr = '127.0.0.1'
definPort = 31001
defoutPort = 22221
defAction = '1stbyte'
defDelta = 10
defExtend = False
trickleDelta = 100
dt = .5
defFrag = -1 #-1 for any fragment
def getArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('-n','--num-recvs',dest='n',action='store',type=int,default=0)
    parser.add_argument('-i','--input-port',dest='ip',action='store',type=int,default=definPort)
    parser.add_argument('-o','--output-port',dest='op',action='store',type=int,default=defoutPort)
    parser.add_argument('-a','--action',dest='ac',action='store',type=str,default='none') 
    parser.add_argument('-d','--delta',dest='delta',action='store',type=int,default=500)
    parser.add_argument('-e','--extend',dest='extend',action='store_true',default=False)
    parser.add_argument('-dir','--direction',dest='direction',action='store',type=str,default='')
    parser.add_argument('-b','--byte',dest='b',action='store',type=int,default=0)
    parser.add_argument('-f','--fragment',dest='frag',action='store',type=int,default=defFrag)
    parser.add_argument('-F','--logfile',dest='logFile',action='store',type=str,default='')
    parser.add_argument('-p','--sizeChange',dest='newSize',action='store',type=int)
    args,unknown = parser.parse_known_args()
    return args
acMap = {
        'lastbyte':lambda x:x[:-1] + b'\xff',
        '1stbyte':lambda x:b'\xff' + x[1:], 
        'custom':lambda x: x[:args.b] + (x[args.b] ^1).to_bytes(1,'little') + x[args.b+1:],
        'customBig':lambda x: x[:args.b] + (x[args.b] ^1).to_bytes(1,'big') + x[args.b+1:],

        'none':lambda x:x,
        }
def log(*st):
    if not args.logFile:
        return
    with open(args.logFile,'a') as f:
        f.write(' '.join([str(i) for i in st]) + '\n')



class handler(socketserver.BaseRequestHandler):
    def handle(self):
        log(f"Received connection: {self.request}")
        handshook = 0
        outConn = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        outConn.connect(('127.0.0.1',args.op))
        log(f"Connected to: 127.0.0.1, {args.op} using ephemeral port {outConn.getsockname()[1]}")
        while True:
            s = select.select([outConn,self.request],[],[])
            curDir = 'out' if s[0][0] == self.request else 'in'

            target = self.request if curDir == 'in' else outConn
            inSock = s[0][0]
            try:
                dat = inSock.recv(10000)
            except:
                log(f'Connection closed from (apparently) {curDir}')
                return
            log('<-' if curDir == 'in' else '->', f'({len(dat)}) byte, {dat!r}', f'Source Port: {self.request.getsockname()[1]}', f'Target Port: {outConn.getsockname()[1]}', f'Timestamp: {time.time()}')
            if args.direction == curDir:
                handshook += 1
                
            if handshook == args.n and args.direction == curDir:
                    log(f"Performing",args.ac,dat == action(dat))
                    dat = action(dat)
                    i = 0
                    while i < len(dat):
                        time.sleep(dt)
                        try:
                            target.send(dat[i:i+args.delta])
                            i += args.delta
                        except:
                            break

                    if args.extend:
                        while True:
                            i += args.delta
                            time.sleep(dt)
                            try:
                                target.send(os.urandom(args.delta))
                            except:
                                break
            else:
                target.send(dat)

            if dat == b'':
                self.request.close()
                outConn.close()
                log(f'Connection closed from (apparently) {curDir}')
                return

                


if __name__ == '__main__':
    args = getArgs()
    action = acMap[args.ac]
    if args.logFile:
        with open(args.logFile,'w') as f:
            log(f'Starting MITM: {args.ip} -> {args.op}\n')

    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(('127.0.0.1',args.ip),handler) as server:
        server.serve_forever()
