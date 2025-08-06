This is a monorepo for Batteries Included, a platform for modern infrastructure
built on Kubernetes, Open Source, and Elixir.

## Project Guidelines

- The project provides a `bix` CLI tool for common tasks, such as running tests,
  formatting code, and linting. You can read the usage instructions by running
  `bix help`.
- Use `bix s fmt` to format all code including Elixir, JavaScript, and CSS.
- Use `bix ex lint` to run all linters including Credo for Elixir.
- Use `bix ex test-deep` to run all elixir tests.
- Use `bix go test` to run all golang tests.

## Project Structure

- platform_umbrella: The elixir umbrella application that contains the control
  server, home base, and other platform components.
- bi: the Batteries Included CLI tool built with golang and Pulumi.
- static: The static website built with Astro.
- docker: the Dockerfiles for the platform and example applications.
- keycloak-theme: The Keycloak theme styling via keycloakify, tailwindcss, and
  react.
- registry-tool: tool to manage OCI images and the yaml registry that we use to
  store our authoritative image metadata.
- pastebin-go: A simple pastebin application built with Go for testing and
  demonstration purposes.
