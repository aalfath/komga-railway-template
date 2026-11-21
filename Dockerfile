# Komga packaged for Railway: the official image, pinned by version and digest,
# plus a small start script. Bump the tag and digest together, and add a
# CHANGELOG.md entry: a merge to main notifies everyone who deployed the template.
FROM gotson/komga:1.30.1@sha256:d43bb3b57aeeafd274ea805214f5da71ff9306accf012fb14cc13dedc3307212

# Everything Komga writes lives under /data (the Railway volume):
#   /data/config   SQLite databases, Lucene search index, fonts, logs
#   /data/library  your comics, manga and books (the "Library" library)
ENV KOMGA_CONFIGDIR=/data/config \
    LOGGING_LOGBACK_ROLLINGPOLICY_TOTAL_SIZE_CAP=50MB \
    LOGGING_LOGBACK_ROLLINGPOLICY_MAX_HISTORY=3 \
    JAVA_TOOL_OPTIONS="-Xmx1g"

COPY start.sh /usr/local/bin/komga-railway-start
RUN chmod 0755 /usr/local/bin/komga-railway-start && command -v curl >/dev/null

# The upstream ENTRYPOINT also passes --spring.config.additional-location=file:/config/,
# which fails when /config doesn't exist (Railway ignores the image's VOLUME /config).
# Komga already reads an optional application.yml from its config dir on the volume.
ENTRYPOINT ["/usr/local/bin/komga-railway-start"]
