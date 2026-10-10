# home-gateway

Two containers for a personal VPN back to your home network:

- **ddns**: keeps a Cloudflare A record (`VPN_HOSTNAME`) pointed at your public IPv4 address.
- **wireguard**: a WireGuard server (the upstream linuxserver image) with one peer, full tunnel,
  using your Pi-hole for DNS.

Only one UDP port is exposed. WireGuard doesn't answer unauthenticated packets, so scanners see nothing.

## Deploy
1. Push to GitHub; the workflow publishes `ghcr.io/<owner>/home-gateway:main` (ddns image).
2. On TrueNAS, install `deploy.yaml` as a custom app and set the variables listed in `.env.example`.
3. Forward UDP 51820 on your router to the TrueNAS host.
4. Show the phone's config QR code: `docker exec <wireguard container> /app/show-peer phone`.
5. Test over mobile data before relying on it.

## Notes
- The DNS record is DNS-only (not proxied); Cloudflare's proxy can't carry WireGuard.
- Pi-hole sees tunnel queries from the TrueNAS host's LAN address; allow it in Pi-hole's interface settings if needed.
- If you lose the phone, delete the peer from the wireguard config volume and restart.
- Behind CGNAT, port forwarding won't work.

## IPv6
The peer routes `::/0` into the tunnel so IPv6 can't bypass it and leak a non-UK address. The server
has no IPv6 route, so those packets are dropped and apps fall back to IPv4 through the tunnel.
Changing `ALLOWEDIPS` regenerates the peer config: delete and re-add the tunnel on the phone.
