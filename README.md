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

Branches should be rebased to `main` to keep the history on the main branch clear and easy to follow.

Branches should be completed and sent for review via Pull Request and merged into main via squashed merge-commit to keep noise in main down.

# Code Standards
How do we conduct code review
What are norms we want to enforce

For code reviewers 
*Borrowed from [18F code review standards](https://guides.18f.org/engineering/our-approach/code-review/)*

- Understand why the code is necessary (bug, user experience, refactoring)
- Seek to understand the author's perspective.
- Clearly communicate which ideas you feel strongly about and those you don't.
- Identify ways to simplify the code while still solving the problem.
- Offer alternative implementations, but assume the author already considered them. ("What do you think about such-and-such here?")
- Sign off on the pull request with a :thumbsup: or "Ready to merge" comment.
- Wait to merge the branch until it has passed Continuous Integration testing.
- Use [Conventional Comments](https://conventionalcomments.org/) in order to clarify whether a comment is blocking or non-blocking for merging the PR.

# Testing
*When do we use feature tests / integration / regression / unit tests*

RSpec is the test runner. Use `bundle exec rspec {file}{:ln}` command to run individual tests, including relative file path (`file`) and line number (`ln`) 

## Test Standards
Use a TDD approach when shipping new features.

- New controller actions MUST have controller specs (see `spec/controllers/*_spec.rb`).
- New services and model methods should include unit specs under `spec/services` or `spec/models`.
- When adding a new API endpoint, add request specs under `spec/requests` and examples of expected JSON input/output.

## Test Coverage

To check test coverage with RSPEC:
`COVERAGE=true bundle exec rspec {my_spec_file}`

 Note that when running this command your coverage file will show that all other files don't have coverage.

# Authorization

Authorization uses Pundit; look for policies in `app/policies` and checks in controllers.

To add an admin-only action: check `app/policies/*Policy.rb` for authorization and add tests in `spec/policies` and `spec/controllers`.

# Debugging

In order to see what you are typing when debugging with `binding.pry` , use `rails s -p 3001` instead of `make run`

# Linting

## We lint with Rubocop and ESLint

* Ruby using Rubocop rules. These rules are currently under active development.

* JavaScript using ESLint. We use [the ESLint plugin from IdP](https://github.com/18F/identity-idp/tree/main/app/javascript/packages/eslint-plugin) as well as some rules to ensure we don't error on upstream dependencies that use variant linting rules or minified compiled assets.

# Documentation
* YARD docs to ensure they have no warnings and also we enforce that the `LogEvents` class has YARD documentation for all its methods

You can see the YARD docs for yourself by running `bin/yard` and then opening [doc/yard/index.html] in a browser. Doing so should show you this README with links to documented classes. Currently, we aren't including YARD doc generation in our build process and then committing them, though this may change later.

# License

[The project is in the public domain](LICENSE.md), and all contributions will also be released in the public domain. By submitting a pull request, you are agreeing to waive all rights to your contribution under the terms of the [CC0 Public Domain Dedication](http://creativecommons.org/publicdomain/zero/1.0/).

This project constitutes an original work of the United States Government.
