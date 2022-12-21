const fs = require('fs');
const path = require('path');

module.exports = class File {
    static read(file) {
        return fs.readFileSync(file, 'utf8');
    }

    static write(file, content) {
        fs.open(file, "w", (error, fd) => {
            fs.writeFile(file, content, err => {
                if (err) {
                    console.error(err);
                }
            });
            fs.close(fd);
        });
    }
}