FROM node:14 as deps

WORKDIR /calcom

COPY calendso/package.json calendso/yarn.lock calendso/turbo.json ./
COPY calendso/apps/web ./apps/web
COPY calendso/packages ./packages
# COPY calendso/apps/web/package.json calendso/apps/web/yarn.lock ./apps/web/
# COPY calendso/packages/prisma/package.json ./packages/prisma/package.json
# COPY calendso/packages/prisma/schema.prisma ./packages/prisma/schema.prisma
# COPY calendso/packages/lib/package.json ./packages/lib/package.json
# COPY calendso/packages/tsconfig/package.json ./packages/tsconfig/package.json

# COPY calendso/packages/config/package.json ./packages/config/package.json
# COPY calendso/packages/ee/package.json ./packages/ee/package.json
# COPY calendso/packages/ui/package.json ./packages/ui/package.json
# COPY calendso/packages/stripe/package.json ./packages/stripe/package.json
# COPY calendso/packages/app-store/package.json ./packages/app-store/package.json
# COPY calendso/packages/core/package.json ./packages/core/package.json
# COPY calendso/packages/types/package.json ./packages/types/package.json

# RUN yarn install --frozen-lockfile

RUN yarn install

# RUN yarn install

FROM node:14 as builder

WORKDIR /calcom
ARG BASE_URL
ARG NEXT_PUBLIC_APP_URL
ARG NEXT_PUBLIC_WEBAPP_URL
ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG NEXT_PUBLIC_TELEMETRY_KEY
ENV BASE_URL=$BASE_URL \
  NEXT_PUBLIC_WEBAPP_URL=$NEXT_PUBLIC_WEBAPP_URL \
  NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL \
  NEXT_PUBLIC_BASE_URL=$NEXT_PUBLIC_BASE_URL \
  NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
  NEXT_PUBLIC_TELEMETRY_KEY=$NEXT_PUBLIC_TELEMETRY_KEY

COPY calendso/package.json calendso/yarn.lock calendso/turbo.json ./
COPY calendso/apps/web ./apps/web
COPY calendso/packages ./packages
# copy email body logo to web folder
COPY email_body_logo.png ./apps/web/public/emails/CalLogo@2x.png
COPY favicon.ico ./apps/web/public/favicon.ico
COPY --from=deps /calcom/node_modules ./node_modules
RUN yarn build && yarn install --production --ignore-scripts --prefer-offline

FROM node:14 as runner
WORKDIR /calcom
ENV NODE_ENV production
RUN apt-get update && \
  apt-get -y install netcat && \
  rm -rf /var/lib/apt/lists/* && \
  yarn add prisma

COPY calendso/package.json calendso/yarn.lock calendso/turbo.json ./
COPY --from=builder /calcom/node_modules ./node_modules
COPY --from=builder /calcom/packages ./packages
COPY --from=builder /calcom/apps/web/node_modules ./apps/web/node_modules
COPY --from=builder /calcom/apps/web/scripts ./apps/web/scripts
COPY --from=builder /calcom/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=builder /calcom/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js
COPY --from=builder /calcom/apps/web/public ./apps/web/public
COPY --from=builder /calcom/apps/web/.next ./apps/web/.next
COPY --from=builder /calcom/apps/web/package.json ./apps/web/package.json
COPY  scripts scripts

EXPOSE 3000
CMD ["/calcom/scripts/start.sh"]