module.exports = class Strings
{
    static stringSize(text) 
    {
        return text.length;
    }

    static stringReplace(text, toReplace, replacement)
    {
        return text.replace(toReplace, replacement);
    }

    static stringSub(text, startInt, endInt)
    {
        return text.substr(startInt, endInt);
    }
}