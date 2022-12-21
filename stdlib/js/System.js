var exec = import('child_process').exec;

module.exports = class System {

    static runcmd(cmd) {
        exec(cmd,
            null
        );
    }

    static shutdown(exitcode) {
        throw new Error();
    }

    static varTrace(vari) {
        console.log("" + vari);
    }

}