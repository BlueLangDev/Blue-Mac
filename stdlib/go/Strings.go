package main

import "strings"

func stringSize(s dynamic) dynamic {
	return len(s.(string))
}

func stringReplace(text dynamic, toReplace dynamic, replacement dynamic) dynamic {
	return strings.Replace(text.(string), toReplace.(string), replacement.(string), -1);
}

func stringSub(text dynamic, startInt dynamic, endInt dynamic) dynamic {
	return (text.(string))[startInt.(int):endInt.(int)]
}