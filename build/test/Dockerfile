FROM mvertes/alpine-mongo
MAINTAINER Sebastian Katzer "katzer.sebastian@googlemail.com"

ENV BUILD_PACKAGES ruby-dev gcc make libc-dev
ENV RUBY_PACKAGES ruby git ruby-io-console

RUN apk update && \
    apk add --no-cache $BUILD_PACKAGES && \
    apk add --no-cache $RUBY_PACKAGES && \
    gem install bundler --no-ri --no-rdoc

ENV APP_HOME /usr/app/
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile $APP_HOME
COPY Gemfile.lock $APP_HOME
RUN bundle install --path vendor/bundle --no-cache --without development

COPY . $APP_HOME

ENV MONGO_URI=mongodb://localhost:27017/appdax

CMD ["bundle", "exec", "rspec spec --fail-fast --failure-exit-code 1 && codeclimate-test-reporter"]
