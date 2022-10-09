.PHONY: compile test lint analyze format

all: deps.get compile test lint format analyze

compile:
	mix compile --force --warnings-as-errors
	MIX_ENV=test mix compile --force --warnings-as-errors
	mix compile.protocols 
	MIX_ENV=test mix compile.protocols 

lint:
	mix credo

test: compile test.unit
	mix test.coverage

test.unit: compile
	MIX_ENV=test mix ecto.reset
	mix test --cover --export-coverage default

test.integration:
	MIX_ENV=integration mix ecto.reset
	MIX_ENV=integration mix cmd --app control_server_web mix test  --cover --export-coverage integration

analyze:
	mix dialyzer

deps.get:
	mix deps.get
	mix deps.compile

format: deps.get
	mix fmt
