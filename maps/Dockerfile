# yokan-ark: ASA server wrapper image
# Base image: mschnitzer/asa-linux-server
# - One image supports multiple maps.
# - Map selection is done via env: MAP_ID / SESSION_NAME / PORT.

FROM docker.io/mschnitzer/asa-linux-server:latest

COPY entrypoint.sh /usr/local/bin/yokan-entrypoint.sh
RUN chmod +x /usr/local/bin/yokan-entrypoint.sh

USER gameserver
ENTRYPOINT ["/usr/local/bin/yokan-entrypoint.sh"]
