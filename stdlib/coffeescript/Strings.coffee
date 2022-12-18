class Strings

stringSize = (text) ->
return text.length

stringReplace = (text, fromText, toText) ->
return text.replace(fromText, toText)

stringSub = (text, startInt, endInt) ->
return text.substr(startInt, endInt)