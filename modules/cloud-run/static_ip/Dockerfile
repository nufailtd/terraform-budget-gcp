FROM python:3-alpine

RUN apk add --no-cache ca-certificates bash
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini

# Add chisel for tunneling
COPY --from=jpillora/chisel /app/chisel /usr/local/bin/chisel

# Add berglas for secrets management
COPY --from=us-docker.pkg.dev/berglas/berglas/berglas:latest /bin/berglas /usr/local/bin/berglas
RUN chmod +x /usr/local/bin/berglas

WORKDIR /app
COPY . /app
RUN chmod +x ./entrypoint.sh
RUN pip install -r requirements.txt

ENTRYPOINT ["/tini", "--", "./entrypoint.sh"]
