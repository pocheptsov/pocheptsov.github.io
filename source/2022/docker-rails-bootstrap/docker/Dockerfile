ARG RUBY_VERSION=3.1.2
ARG DEBIAN_CODENAME=bullseye
FROM ruby:$RUBY_VERSION-$DEBIAN_CODENAME

ENV APP_DIR=/app
ARG UID=1000
ARG GID=1000

RUN groupadd --gid $GID user \
  && useradd --no-log-init --uid $UID --gid $GID user --create-home \
  \
  && mkdir -p $APP_DIR \
  && chown -R $UID:$GID $APP_DIR \
  \
  && gem update bundler \
  && chown -R $UID:$GID /usr/local/bundle \
  && bundler --version

# copy files required for `bundle install` step
COPY --chown=$UID:$GID Gemfile* $APP_DIR/

# entry point setup
COPY --chmod=755 docker/entrypoint.sh /usr/bin/

# switching to app user
USER $UID:$GID
WORKDIR $APP_DIR

RUN echo "!!!!! Install gems !!!!!" \
  && bundle install -j "$(($(nproc)+1))"

ENTRYPOINT ["entrypoint.sh"]

CMD /bin/bash
