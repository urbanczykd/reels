FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libyaml-dev \
  ffmpeg \
  nodejs \
  git \
  curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY . .

RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile

EXPOSE 3000
