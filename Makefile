all: tracket

tracket: main.rkt
	raco exe --vv -o tracket main.rkt


