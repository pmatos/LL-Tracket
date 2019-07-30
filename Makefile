all: tracket

tracket: main.rkt
	raco exe -o tracket main.rkt


