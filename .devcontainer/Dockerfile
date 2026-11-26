FROM pandoc/core:3.8.3-ubuntu AS pandoc

FROM node:26.12.1-trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends fonts-noto-cjk jq libgmp10 liblua5.4-0 sudo weasyprint zlib1g zsh \
    && rm -rf /var/lib/apt/lists/* \
    && printf 'node ALL=(root) NOPASSWD: /usr/bin/chown\n' > /etc/sudoers.d/node
COPY --from=pandoc /usr/local/bin/pandoc /usr/local/bin/pandoc
COPY package.json /tmp/codimd-package.json
RUN npm install -g "$(node -p 'require("/tmp/codimd-package.json").packageManager')"
