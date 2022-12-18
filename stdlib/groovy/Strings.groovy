class Strings {

    def stringSize(text) {
        return text.length();
    }
    
    def stringReplace(text, toReplace, replacement) {
        return text.replace(toReplace, replacement);
    }

    def stringSub(text, startInt, endInt) {
        return text.substring(startInt, endInt);
    }
}