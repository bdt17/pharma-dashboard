FROM ruby:3.4-slim

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* 

WORKDIR /rails
COPY config config/
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install
COPY . .
EXPOSE $PORT
CMD ["sh", "-c", "rm -f tmp/pids/server.pid && rails server -b 0.0.0.0 -p $PORT"]
