## FROM mirror.gcr.io/library/ghost ##
FROM ghost:alpine

# Add tini to run multiple processes in container
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini

COPY start.sh /start.sh
RUN chmod +x /start.sh

# Add chisel for tunneling
COPY --from=jpillora/chisel /app/chisel /usr/local/bin/chisel

# Add berglas for secrets management
COPY --from=us-docker.pkg.dev/berglas/berglas/berglas:latest /bin/berglas /usr/local/bin/berglas
RUN chmod +x /usr/local/bin/berglas

ENTRYPOINT ["tini", "-vvv", "--", "/start.sh"]