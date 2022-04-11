.PHONY: compile test lint analyze format

all: compile test lint format analyze

compile:
	mix compile --force --warnings-as-errors

lint:
	mix credo

test:
	mix test --cover --export-coverage default
	mix test.coverage

analyze:
	mix dialyzer

deps.get:
	mix deps.get
	mix deps.compile

format: deps.get
	mix fmt
