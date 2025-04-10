# Login.gov Partner Dashboard

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

In the development environment, an administrator user account is created during the setup process with the email address _admin@gsa.gov_ . If this is the first time you've run the application, you will want to log in with this email address, or create an account if one doesn't already exist. After you've logged in as the administrator, you can add new users and teams.

Alternatively, log in using any account, then promote the user to an admin using the `users:make_admin` Rake task:

`bundle exec rake users:make_admin USER=user@example.com,First,Last`

## Running tests

Run RSpec tests using:

```
$ make test
```

## Branching Strategy

Branches should be specifically named in a standard format that closely matches the current style of `[TICKET-NUMBER]-feature-name/user-ticket-what-the-branch-does` This will group the branches of the feature together, and easily identified

Branches should be specific to a specific feature. Sub-branches can be created for larger features that require development broken into multiple parts for completion.

Branches should be rebased to main to keep the history on the main branch clear and easy to follow.

Branches should be completed and sent for review via Pull Request and merged into main via squashed merge-commit to keep noise in main down.

# Code Standards
How do we conduct code review
What are norms we want to enforce

TBD

# Testing Standards
When do we use feature tests / integration / regression / unit tests
What do we always want to test

TBD

# Linting / Rubocop
When do we delete code, cleaning up old feature flags
Linters and settings we have setup

TBD


## License

[The project is in the public domain](LICENSE.md), and all contributions will also be released in the public domain. By submitting a pull request, you are agreeing to waive all rights to your contribution under the terms of the [CC0 Public Domain Dedication](http://creativecommons.org/publicdomain/zero/1.0/).

This project constitutes an original work of the United States Government.
