[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/komga-1?utm_medium=integration&utm_source=button&utm_campaign=komga)

# Komga on Railway

[Komga](https://komga.org) (MIT) as a Railway template: a media server for comics, manga, BDs, magazines and ebooks, with a web reader, OPDS feeds, Kobo Sync and KOReader Sync. The service builds from this repository, so when `main` moves to a newer Komga release, Railway offers the update to everyone who deployed the template.

Version: **Komga 1.30.1**, official image `gotson/komga:1.30.1@sha256:d43bb3b57aeeafd274ea805214f5da71ff9306accf012fb14cc13dedc3307212`.

## What it deploys

| Railway service | Source | Volume | Role |
|---|---|---|---|
| `Komga` | this repo (`Dockerfile`, `start.sh`) | `/data` | Web UI, reader, OPDS and REST API on a public domain |

Komga keeps its data in embedded SQLite databases and a Lucene index, so there is no separate database service. Everything lives on the one volume:

- `/data/config`: databases (`database.sqlite`, `tasks.sqlite`, `sessions.sqlite`), search index, fonts, logs, and an optional `application.yml`
- `/data/library`: your books. The template creates a library called **Library** pointing here, scanned on every start and every 6 hours.

## First boot

`start.sh` starts Komga on `PORT` (25600) and, while the server is still unclaimed, claims it for `KOMGA_ADMIN_EMAIL` with the generated `KOMGA_ADMIN_PASSWORD` and creates the **Library** library. An unclaimed Komga would let whoever opens the URL first become admin; claiming it at boot closes that gap. Both steps run only on a fresh volume, so a redeploy never resets accounts or libraries you changed in the web UI.

Find the password in the service's **Variables** tab, sign in, and change it under **Account settings** if you like. Changing the variable later does not change the account.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `KOMGA_ADMIN_EMAIL` | `admin@example.com` | Login of the first admin; must look like an email. Change it at deploy time if you like |
| `KOMGA_ADMIN_PASSWORD` | `${{secret(24)}}` | Generated password for that admin |
| `PORT` | `25600` | Port Komga listens on and the domain targets |

Optional: `JAVA_TOOL_OPTIONS` (default `-Xmx1g`) for very large libraries, `TZ` for the server's time zone. Any Komga setting from the [configuration docs](https://komga.org/docs/installation/configuration) can be set as an environment variable (for example `KOMGA_OAUTH2_ACCOUNT_CREATION`), or in `/data/config/application.yml`.

## Adding books

Komga has no web upload. Put files on the volume with the Railway CLI, one folder per series:

```sh
railway volume files upload ./My-Series /data/library/My-Series
```

Then choose **Scan library files** on the library, or redeploy. Use **Server settings → Libraries** to add more libraries under `/data`.

## Updates

Each release of this repo pins one Komga version by tag and digest in `Dockerfile`. When it changes on `main`, Railway shows deployers an update notice; read [CHANGELOG.md](CHANGELOG.md) first (breaking changes are listed first), then apply it. Komga migrates its databases on start. Take a volume backup in Railway before big jumps.

## Local test

```sh
docker build -t komga-railway .
docker run --rm -p 25600:25600 -v komga-data:/data \
  -e KOMGA_ADMIN_EMAIL=admin@example.com -e KOMGA_ADMIN_PASSWORD=change-me komga-railway
```
