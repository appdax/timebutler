FROM alpine:3.3
MAINTAINER Sebastian Katzer "katzer@appplant.de"

ENV BUILD_PACKAGES ruby-dev gcc make libc-dev tzdata
ENV RUBY_PACKAGES ruby tar ruby-bundler ruby-io-console

RUN apk update && \
    apk add --no-cache $BUILD_PACKAGES && \
    apk add --no-cache $RUBY_PACKAGES && \
    gem update bundler --no-ri --no-rdoc

RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN echo "Europe/Berlin" > /etc/timezone

ENV APP_HOME /usr/app/
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile $APP_HOME
COPY Gemfile.lock $APP_HOME
RUN bundle config path vendor/bundle
RUN bundle install --no-cache --without development test

COPY . $APP_HOME

RUN apk del $BUILD_PACKAGES && \
    gem uninstall minitest test-unit power_assert && \
    gem clean && \
    rm -rf /var/cache/apk/* && \
    rm -rf /usr/share/ri && \
    rm -rf $APP_HOME/vendor/bundle/cache/*.gem && \
    rm -rf $APP_HOME/vendor/bundle/extensions/* && \
    rm -rf $APP_HOME/vendor/bundle/gems/*/test && \
    rm -rf $APP_HOME/vendor/bundle/gems/*/spec && \
    rm -rf $APP_HOME/vendor/bundle/gems/*/doc && \
    rm -rf $APP_HOME/vendor/bundle/gems/*/examples && \
    rm -rf $APP_HOME/vendor/bundle/gems/**/*.md && \
    rm -rf $APP_HOME/.git && \
    rm -rf $APP_HOME/spec

RUN chmod -R +x bin
RUN bundle exec whenever -i

CMD ["./bin/init"]
