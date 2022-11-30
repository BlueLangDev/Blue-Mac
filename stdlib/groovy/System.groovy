def runcmd(cmd) {
   println cmd.execute().text;
}

def close(exitCode) {
    return exitCode;
}

def varTrace(vari) {
   println(vari);
}