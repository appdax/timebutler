FROM alpine:3.4
MAINTAINER Sebastian Katzer "katzer.sebastian@googlemail.com"

ENV APP_HOME /usr/app/
ENV BUILD_PACKAGES ruby-dev gcc make libc-dev tzdata
ENV RUBY_PACKAGES ruby tar ruby-io-console

RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME

COPY Gemfile $APP_HOME
COPY Gemfile.lock $APP_HOME

RUN apk update && \
    # Install Ruby packages
    apk add --no-cache $BUILD_PACKAGES && \
    apk add --no-cache $RUBY_PACKAGES && \
    # Timezone
    cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone && \
    # Bundle
    gem install bundler --no-ri --no-rdoc && \
    bundle install --path vendor/bundle --no-cache --without development test && \
    # Cleanup
    apk del $BUILD_PACKAGES && \
    gem uninstall minitest test-unit power_assert net-telnet && \
    rm -rf /var/cache/apk/* && \
    rm -rf vendor/bundle/cache/*.gem && \
    rm -rf vendor/bundle/extensions/* && \
    rm -rf vendor/bundle/gems/*/test && \
    rm -rf vendor/bundle/gems/*/spec && \
    rm -rf vendor/bundle/gems/*/doc && \
    rm -rf vendor/bundle/gems/*/examples && \
    rm -rf vendor/bundle/gems/**/*.md && \
    rm -rf build && \
    rm .dockerignore

RUN chmod +x init && \
    bundle exec whenever -w -r timebutler

CMD ["./init"]
