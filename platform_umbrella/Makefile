.PHONY: test lint analyze docs i

all: test lint  format docs analyze

lint:
	mix credo

test:
	mix test --cover

analyze:
	mix dialyzer

docs:
	mix docs

format:
	mix format 
