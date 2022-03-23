FROM node:14 as deps

WORKDIR /calcom

COPY calendso/package.calendso calendso/yarn.lock ./
COPY calendso/apps/web/package.calendso calendso/apps/web/yarn.lock ./apps/web/
COPY calendso/packages/prisma/package.calendso ./packages/prisma/package.calendso
COPY calendso/packages/prisma/schema.prisma ./packages/prisma/schema.prisma
COPY calendso/packages/lib/package.calendso ./packages/lib/package.calendso
COPY calendso/packages/tsconfig/package.calendso ./packages/tsconfig/package.calendso

COPY calendso/packages/config/package.calendso ./packages/config/package.calendso
COPY calendso/packages/ee/package.calendso ./packages/ee/package.calendso
COPY calendso/packages/ui/package.calendso ./packages/ui/package.calendso
COPY calendso/packages/stripe/package.calendso ./packages/stripe/package.calendso

# RUN yarn install --frozen-lockfile

RUN yarn install

# RUN yarn install

FROM node:14 as builder

WORKDIR /calcom
ARG BASE_URL
ARG NEXT_PUBLIC_APP_URL
ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG NEXT_PUBLIC_TELEMETRY_KEY
ENV BASE_URL=$BASE_URL \
  NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL \
  NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
  NEXT_PUBLIC_TELEMETRY_KEY=$NEXT_PUBLIC_TELEMETRY_KEY

COPY calendso/package.calendso calendso/yarn.lock calendso/turbo.calendso ./
COPY calendso/apps/web ./apps/web
COPY calendso/packages ./packages
COPY --from=deps /calcom/node_modules ./node_modules
RUN yarn build && yarn install --production --ignore-scripts --prefer-offline

FROM node:14 as runner
WORKDIR /calcom
ENV NODE_ENV production
RUN apt-get update && \
  apt-get -y install netcat && \
  rm -rf /var/lib/apt/lists/* && \
  yarn global add prisma

COPY calendso/package.calendso calendso/yarn.lock calendso/turbo.calendso ./
COPY --from=builder /calcom/node_modules ./node_modules
COPY --from=builder /calcom/packages ./packages
COPY --from=builder /calcom/apps/web/node_modules ./apps/web/node_modules
COPY --from=builder /calcom/apps/web/scripts ./apps/web/scripts
COPY --from=builder /calcom/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=builder /calcom/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js
COPY --from=builder /calcom/apps/web/public ./apps/web/public
COPY --from=builder /calcom/apps/web/.next ./apps/web/.next
COPY --from=builder /calcom/apps/web/package.calendso ./apps/web/package.calendso
COPY  scripts scripts

EXPOSE 3000
CMD ["/calcom/scripts/start.sh"]