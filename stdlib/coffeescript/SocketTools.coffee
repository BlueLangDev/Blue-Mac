class SocketTools

net = require('net')

socketsArray = []
trackedSocketsArray = []

lastRead = ""

socketMake = (tag) ->
sock = new net.Socket()
socketsArray.push(sock)
trackedSocketsArray.push(tag)

socketConnect = (tag, port, host) ->
i for i in [0...trackedSocketsArray.length]
if trackedSocketsArray[i] == tag then
sock = socketsArray[i]
sock.connect(port, host)
sock.on('data', (e) => 
lastRead = e)

socketWrite = (tag, data) ->
i for i in [0...trackedSocketsArray.length]
if trackedSocketsArray[i] == tag then
extractedSock = socketsArray[i]
extractedSock.write("#{data}")

socketRead = (tag) ->
i for i in [0...trackedSocketsArray.length]
if trackedSocketsArray[i] == tag then
return lastRead

socketDestroy = (tag) ->
i for i in [0...trackedSocketsArray.length]
if trackedSocketsArray[i] == tag then
extractedSock = socketsArray[i]
extractedSock.destroy()
trackedSocketsArray.remove(trackedSocketsArray[i])
socketsArray.remove(extractedSock)