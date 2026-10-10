FROM alpine:3.20
RUN apk add --no-cache curl jq \
 && adduser -D -u 3004 ddns
COPY update.sh /usr/local/bin/update.sh
USER ddns
# CF_API_TOKEN, CF_ZONE_ID and CF_RECORD_NAME must be supplied at runtime.
ENV INTERVAL=3600 TTL=60
ENTRYPOINT ["/usr/local/bin/update.sh"]
