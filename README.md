[![Code Climate](https://codeclimate.com/github/18F/identity-dashboard/badges/gpa.svg)](https://codeclimate.com/github/18F/identity-dashboard)
[![Test Coverage](https://codeclimate.com/github/18F/identity-dashboard/badges/coverage.svg)](https://codeclimate.com/github/18F/identity-dashboard/coverage)

# Identity-dashboard

An admin dashboard for the Identity project.

[![Build Status](https://travis-ci.org/18F/identity-dashboard.svg?branch=master)](https://travis-ci.org/18F/identity-dashboard)[![security](https://hakiri.io/github/18F/identity-dashboard/master.svg)](https://hakiri.io/github/18F/identity-dashboard/master)

## Getting Started Locally

1. Make sure Postgres is running.  For example, on OS X:

    $ brew services start postgres

1. Run the following command to set up the environment:

    $ make setup

1. Run the app server with:

    $ make run

Note that the web server runs at http://localhost:3001/ by default (not the default Rails port 3000).
This is to make it possible to easily run https://github.com/18F/identity-idp and https://github.com/18F/identity-dashboard
on the same development machine.

## Running Tests

To run all the tests:

    $ make test

See RSpec [docs](https://relishapp.com/rspec/rspec-core/docs/command-line) for
more information.

## License

[The project is in the public domain](LICENSE.md), and all contributions will also be released in the public domain. By submitting a pull request, you are agreeing to waive all rights to your contribution under the terms of the [CC0 Public Domain Dedication](http://creativecommons.org/publicdomain/zero/1.0/).

This project constitutes an original work of the United States Government.
