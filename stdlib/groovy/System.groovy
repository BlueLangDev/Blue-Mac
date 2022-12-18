class System 
{

def runcmd(cmd) {
   println cmd.execute().text;
}

def shutdown(exitCode) {
   return exitCode;
}

def varTrace(vari) {
   println(vari);
}
}