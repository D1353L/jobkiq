FROM ruby:3.4.7-alpine3.22

RUN apk add --no-cache \
  git \
  build-base \
  yaml-dev \
  bash \
  libxml2-dev \
  libxslt-dev

WORKDIR /app
COPY . .
RUN bundle install
