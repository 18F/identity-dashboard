# identity-reporting

Summary reports of login.gov activity

## Development

### Run Development Server

```bash
npm install
npm start
```

View the application at http://localhost:3000/

### Viewing Reports with Local Data

Normally local development can view production data. However, when developing and interating
on a new report, you may want to test locally.

With the [development server running](#run-development-server)

1. Add query param `?env=local`
2. Drop report files into a `local` directory at the top of the repo
    File paths will need to match the production paths, so for example:
    | environment | path |
    |-------------|------|
    | production  | `/prod/daily-auths-report/2023/2023-01-15.daily-auths-report.json` |
    | local       | `/local/daily-auths-report/2023/2023-01-15.daily-auths-report.json` |

### Run Tests

```
npm run test
```
