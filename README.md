# Identity Dashboard

[![Build Status](https://travis-ci.org/18F/identity-dashboard.svg?branch=master)](https://travis-ci.org/18F/identity-dashboard) [![Code Climate](https://codeclimate.com/github/18F/identity-dashboard/badges/gpa.svg)](https://codeclimate.com/github/18F/identity-dashboard) [![Test Coverage](https://codeclimate.com/github/18F/identity-dashboard/badges/coverage.svg)](https://codeclimate.com/github/18F/identity-dashboard/coverage) [![security](https://hakiri.io/github/18F/identity-dashboard/master.svg)](https://hakiri.io/github/18F/identity-dashboard/master)

An admin dashboard for the Identity project.

## Running locally

These instructions assume [`identity-idp`](https://github.com/18F/identity-idp) is also running locally at `http://localhost:3000`. This dashboard is configured to run on `http://localhost:3001`.

1. Make sure Postgres is running. For example, on macOS:

  ```
  $ brew services start postgres
  ```

2. Set up the environment with:

  ```
  $ make setup
  ```

3. And run the app server:

  ```
  $ make run
  ```

## Running tests

Run RSpec tests using:

```
$ make test
```

## License

[The project is in the public domain](LICENSE.md), and all contributions will also be released in the public domain. By submitting a pull request, you are agreeing to waive all rights to your contribution under the terms of the [CC0 Public Domain Dedication](http://creativecommons.org/publicdomain/zero/1.0/).

This project constitutes an original work of the United States Government.
