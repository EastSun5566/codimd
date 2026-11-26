ARG NODE_VERSION=26.12.1
FROM node:${NODE_VERSION}-trixie-slim AS dependencies

WORKDIR /home/hackmd/app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN npm install -g "$(node -p 'require("./package.json").packageManager')" \
    && npm cache clean --force

FROM dependencies AS build
RUN pnpm install --frozen-lockfile
COPY babel.config.js webpack.common.js webpack.htmlexport.js webpack.prod.js ./
COPY public ./public
COPY utils ./utils
RUN pnpm build

FROM dependencies AS production-dependencies
RUN pnpm install --frozen-lockfile --prod

# The official build embeds the data files that Pandoc needs in sandbox mode.
FROM pandoc/core:3.8.3-ubuntu AS pandoc

FROM node:${NODE_VERSION}-trixie-slim AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates fonts-noto-cjk libgmp10 liblua5.4-0 tini weasyprint zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1500 hackmd \
    && useradd -m -u 1500 -g hackmd hackmd

ENV NODE_ENV=production
WORKDIR /home/hackmd/app
COPY --from=pandoc /usr/local/bin/pandoc /usr/local/bin/pandoc
COPY --from=production-dependencies /home/hackmd/app/node_modules ./node_modules
COPY app.js config.js package.json LICENSE ./
COPY .sequelizerc.example .sequelizerc
COPY lib ./lib
COPY locales ./locales
COPY bin ./bin
COPY utils ./utils
COPY --from=build /home/hackmd/app/public ./public
COPY --chmod=755 deployments/docker-entrypoint.sh /usr/local/bin/codimd-entrypoint
RUN install -d -o hackmd -g hackmd public/uploads

USER hackmd
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "codimd-entrypoint"]

FROM runtime AS app
