#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -gt 0 ]]; then
    exec "$@"
fi

# run DB migrate
if [[ "${CMD_AUTO_MIGRATE:-true}" = "true" ]] && [[ -f .sequelizerc ]]; then
    ./node_modules/.bin/sequelize db:migrate
fi

exec node app.js
