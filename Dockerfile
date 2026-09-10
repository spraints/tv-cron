FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    git \
    python3 \
    python3-pip \
    python3-venv \
    ruby3.3 \
    ruby-nokogiri \
    && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv && . /opt/venv/bin/activate && \
  pip install \
    'samsungtvws[async,cli,encrypted] @ git+https://github.com/xchwarze/samsung-tv-ws-api.git@b00c85c509640d69434a347b0444b983739589e6'

COPY fs/ /

VOLUME /var/data
ENV DATA_DIR=/var/data

CMD ["/docker-entrypoint.sh"]
