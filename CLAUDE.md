# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Deploy

```bash
npx wrangler deploy          # deploy to Cloudflare (requires auth)
npx wrangler dev             # local dev server (Durable Objects run locally)
```

Pushes to `main` auto-deploy via `.github/workflows/deploy.yml` using repo secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

## Architecture

This is a **Cloudflare Workers** project — no Node.js server, no build step for the frontend.

```
src/worker.js          — Worker entry point: routes /gm3/api/signal/ws to the DO, serves static assets
src/signaling-do.js    — SignalingRoom Durable Object: WebRTC signaling relay (in-memory, no persistence)
_site/gm3/index.html   — Full game frontend (~4600 lines, single file, inline JS/Canvas)
wrangler.jsonc         — Cloudflare config: name, routes, DO bindings, migrations
```

### Multiplayer stack

- **Signaling**: Browser opens a WebSocket to `/gm3/api/signal/ws?peerId=<id>`. The Worker forwards it to a `SignalingRoom` Durable Object selected by WAN IP (auto-grouping same-network players) or an explicit `?room=code` param.
- **Peer discovery**: The DO sends the new peer the existing peer list (`peers`), and notifies others (`peer-joined`). It relays `signal` messages between peers for SDP/ICE exchange.
- **Game transport**: After signaling, browsers form direct **WebRTC DataChannels** (unordered, no retransmits). The host broadcasts authoritative game state; clients send input.
- **Host election**: Determined by highest benchmark score among connected peers.

### Lobby flow

`lobby` → `countdown` → `game` / `observer` → `gameover`

12 player slots. A player readies by holding their up (up-arrow or W) button ~2 s. Once ≥1 slot is ready, a 3 s countdown begins. Host broadcasts `game-start` to begin.

### Durable Object notes

`SignalingRoom` uses `state.acceptWebSocket` (Hibernatable WebSockets API) — no persistent storage. The `migrations` entry in `wrangler.jsonc` (`new_sqlite_classes`) is required by Cloudflare even though no SQLite storage is used.

### Static assets

`_site/` is served via the `ASSETS` binding. The route `erd.mmec.ca/gm3/*` maps the entire worker (assets + API) to that path on the shared `mmec.ca` zone.

## Classroom refs

Other repos from the MMEC-CA org are cloned read-only into `/workspaces/classroom-refs/` on every codespace start (`postStartCommand` in `.devcontainer/devcontainer.json`). `gm1` in that directory is the reference implementation this repo was based on.

## Design Notes

Interface respects small browser windows. Every update will increment project version formatted as YYYY-MM-DD-aa with aa incrementing (ab ac ad) with each alternation. On a new day change the date and aa starts over at aa. Gameplay may be altered but we are trying to keep the multiplayer framework intact. Entirely new game genera could be requested, but we can expect it to support multiplayer unless told explicitly otherwise.
