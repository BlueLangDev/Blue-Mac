package main

import (
	"math"
)

func arcsine(x2 dynamic) dynamic {
	return math.Asin(x2.(float64))
}

func arccos(x2 dynamic) dynamic {
	return math.Acos(x2.(float64))
}

func cosine(x3 dynamic) dynamic {
	return math.Cos(x3.(float64))
}

func sine(x5 dynamic) dynamic {
	return math.Sin(x5.(float64))
}

func floorValue(x6 dynamic) dynamic {
	return math.Floor(x6.(float64))
}
