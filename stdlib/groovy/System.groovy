def runcmd(cmd) {
   println cmd.execute().text;
}

def close(exitCode) {
    return exitCode;
}

def getTime() {
   return new Date().getTime();
}

def getDate() {
   return new Date().toString();
}

def varTrace(vari) {
   println(vari);
}