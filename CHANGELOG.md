# Changelog

Breaking changes are listed first in each entry. Read the entry before you apply an update on Railway.

## 1.30.1 (2026-11-21): first release

- Komga 1.30.1, official image `gotson/komga:1.30.1` pinned by digest `sha256:d43bb3b57aeeafd274ea805214f5da71ff9306accf012fb14cc13dedc3307212`.
- All state on the Railway volume at `/data` (`/data/config` for databases, index and logs; `/data/library` for books).
- First boot claims the server for `KOMGA_ADMIN_EMAIL` with a generated password and creates the **Library** library; later boots leave accounts and libraries alone.
- README starts with the Deploy on Railway button for the published template `komga-1`.
