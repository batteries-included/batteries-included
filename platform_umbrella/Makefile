.PHONY: compile test lint analyze format

all: compile test lint format analyze

compile:
	mix compile --force --warnings-as-errors

lint:
	mix credo

test: compile test.unit test.integration
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
