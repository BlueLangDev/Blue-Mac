var exec = import('child_process').exec;

class System {

    static runcmd(cmd) {
        exec(cmd,
            null
        );
    }

    static exit(code) {
        throw new Error();
    }

    static close(exitcode) {
        throw new Error();
    }

    static getDate() {
        return Date.now()
    }

    static getTime(exitcode) {
        return Date.getTime();
    }

    static varTrace(vari) {
        console.log("" + vari);
    }

}