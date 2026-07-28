# Docker App

Minimal **Express** hello-world packaged with Docker.

## Run locally

```bash
npm install
node server.js
```

Open [http://localhost:3000](http://localhost:3000).

## Run with Docker

```bash
docker build -t docker-app .
docker run --rm -p 3000:3000 docker-app
```

## Notes

Learning / demo repo. `node_modules` should not be committed — use the included `.gitignore`.
