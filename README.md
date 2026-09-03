# Docker + GitHub Actions — React Version

Same lesson as the plain HTML project, but now the site is a React app.
That adds two new ideas: **`package.json`** (dependencies) and a
**multi-stage Dockerfile** (build the app, then serve it).

If you haven't done the plain HTML/CSS/JS version first, do that one first —
this one builds on it.

## What's different from the plain version

| Plain HTML site | This React site |
|---|---|
| No `package.json` — nothing to install | `package.json` lists React as a dependency |
| Files served as-is | Files must be **built** first (`npm run build`) into a `dist` folder |
| One-stage Dockerfile | **Two-stage** Dockerfile (build stage + serve stage) |

## What's in this folder

| File | What it is |
|---|---|
| `src/App.jsx` | The React component (a button that counts clicks) |
| `package.json` | Lists dependencies (React) and scripts (`dev`, `build`) |
| `Dockerfile` | Two-stage recipe: build the app, then serve it with nginx |
| `.github/workflows/docker-build.yml` | Robot that installs, builds, dockerizes, and tests |

---

## Part 1 — Run it locally (no Docker yet)

```bash
npm install
npm run dev
```

Open the URL it prints (usually `http://localhost:5173`). Click the button.

> ℹ️ **Note on folder names**: an `&` in a folder's path breaks
> `npm run ...` / `npx ...` on Windows (you'd see an error like
> `is not recognized as an internal or external command`). This project's
> folder was renamed to `Github Actions and Docker` to avoid that, so
> `npm install` / `npm run dev` work normally here. Docker was never
> affected either way — it copies files into a clean path inside the
> container regardless of the folder name on your machine.

---

## Part 2 — Why `package.json`?

Open `package.json`. The important parts:

```json
"scripts": {
  "dev": "vite",
  "build": "vite build"
},
"dependencies": {
  "react": "^19.2.8",
  "react-dom": "^19.2.8"
}
```

- **`dependencies`** = code your app needs to run (React itself)
- **`scripts`** = shortcuts (`npm run build` = "run the `build` command")
- `npm install` reads this file and downloads everything listed into `node_modules`

**Why the plain site didn't need this:** it had zero dependencies —
just files a browser already understands. React code (JSX) needs to be
converted into plain JS first — that's what `npm run build` does.

---

## Part 3 — The two-stage Dockerfile

Open `Dockerfile`:

```dockerfile
# ---- Stage 1: build the React app ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- Stage 2: serve the built app with nginx ----
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

**Why two stages, step by step:**

- **Stage 1 (`build`)** uses a `node` image, because building React needs
  Node.js tools. It installs dependencies and runs `npm run build`, which
  outputs plain HTML/CSS/JS into a `dist` folder.
- **Stage 2** starts fresh from `nginx:alpine` (same as the plain site) and
  copies **only the `dist` folder** from Stage 1 — `COPY --from=build`.

**Why not just one stage?** Because Node.js and all your dependencies
(hundreds of MB) are only needed to *build* the site — not to *serve* it.
Throwing that away and keeping just the final `dist` output makes the final
image small and fast, the same size as the plain HTML version.

**Why `npm ci` instead of `npm install`?**
`npm ci` installs exactly what's in `package-lock.json`, nothing more,
nothing less — more reliable for automated builds like this one.

**Why copy `package.json` before the rest of the code?**
Docker caches each step. If only your `.jsx` files change (not your
dependencies), Docker skips re-running `npm ci` and reuses the cached
result — faster rebuilds.

---

## Part 4 — Build and run with Docker

```bash
docker build -t my-react-site:test .
docker run -d -p 8080:80 --name my-react-site-test my-react-site:test
```

Open `http://localhost:8080` — same app, now built and served from Docker.

```bash
docker rm -f my-react-site-test
```

---

## Part 5 — GitHub Actions workflow

Open `.github/workflows/docker-build.yml`. It now has an extra check before
Docker even gets involved:

```yaml
- name: Install dependencies
  run: npm ci
- name: Build React app
  run: npm run build
```

**Why check this separately, before Docker?**
If your React code has an error, you want to know **immediately**, with a
clear Node.js error message — not buried inside a Docker build log. Fail
fast, fail clearly.

After that, it's the same pattern as before: build the Docker image, run
it, `curl` it to prove it responds, then clean up.

---

## Part 6 — Push it to GitHub

```bash
git init
git add .
git commit -m "Beginner React + Docker + GitHub Actions site"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Go to the **Actions** tab on GitHub and watch it install, build, dockerize,
and test — all automatically.

---

## What you learned (on top of the plain HTML lesson)

- `package.json` tracks a project's dependencies and shortcut scripts
- React code needs a **build step** before a browser can run it
- A **multi-stage Dockerfile** lets you build with heavy tools, then ship
  only the small, final result
- `npm ci` is the reliable, automation-friendly version of `npm install`
- Checking your app builds *before* building Docker catches errors faster
