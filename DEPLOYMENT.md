# Deployment Instructions

## Prerequisites

Before deploying, make sure you have the following software installed on your machine:

- Node.js (v14 or newer)
- Docker (v20.10 or newer)

The following environment variables are used for deployment:

- `FONTAWESOME_TOKEN`: This token is used for authentication with the FontAwesome service. You need to obtain a valid token from your FontAwesome account and use it here. Please make sure not to expose this token publicly.

## Local Deployment

### Steps:

1. Install the dependencies:

```bash
npm install
```

2. Run Webpack to build the project:

```bash
npm run prod
```

3. Run the application:

```bash
swift run
```

You should now be able to see the application running at `localhost:8080`.

## Production Deployment

For deploying to production, we recommend using [Railway](https://railway.app/). Railway is a platform that allows you to deploy your application to the cloud with ease. It also provides a free tier that is sufficient for deploying this application.
