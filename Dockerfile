FROM ruby:3.3-slim
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
WORKDIR /rails
COPY config config/
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install
COPY . .
EXPOSE $PORT
CMD ["sh", "-c", "rm -f tmp/pids/server.pid && rails server -b 0.0.0.0 -p $PORT"]
