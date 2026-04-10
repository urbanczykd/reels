FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  ffmpeg \
  nodejs \
  npm \
  git \
  curl \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g yarn

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile 2>/dev/null || true

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000
