class System

runcmd: (cmd) ->
exec = require('child_process').exec
exec cmd, (error, stdout, stderr) -> null

close: (exitcode) ->
throw new Error()

getDate: () ->
return Date.now()

getTime: () ->
return Date.getTime()

varTrace: (vari) ->
console.log(vari)