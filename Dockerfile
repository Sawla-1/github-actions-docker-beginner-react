# ---- Stage 1: build the React app ----
FROM node:20-alpine AS build

WORKDIR /app

# Copy only the dependency files first (so Docker can cache npm install)
COPY package.json package-lock.json ./
RUN npm ci

# Now copy the rest of the source and build it
COPY . .
RUN npm run build
# This produces a /app/dist folder full of plain HTML/CSS/JS

# ---- Stage 2: serve the built app with nginx ----
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

# Grab ONLY the built output from Stage 1 (not node_modules, not src)
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
