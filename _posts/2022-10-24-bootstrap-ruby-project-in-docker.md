---
layout: post
title: Bootstrap Ruby project in Docker
date: 2022-10-24 22:49:20 -0400
description:  # Add post description (optional)
img: bootstrap-ruby-project-in-docker/ian-taylor-HjBOmBPbi9k-unsplash.jpg # Add image post (optional)
fig-caption: # Add figcaption (optional)
tags: [Docker, Ruby]
---
In the Ruby community, we have a lot of tools to help us to create a new project. But, if you are a beginner, you can be lost in the middle of all these tools. This code is a simple way to start a new project in Ruby using `Docker` without `Rails`, `dip` or any other framework dependencies.
Great examples to start a new project in Ruby:
 - [Ruby on Whales](https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development)
 - [Dockerizing a Ruby on Rails Application](https://semaphoreci.com/community/tutorials/dockerizing-a-ruby-on-rails-application)
 - [Setting Up Development Environment for Rails](https://www.akshaykhot.com/setting-up-development-environment-for-rails/)

## Development environment

### Requirements
Installed Docker with BuildKit support and docker-compose are required:
 - [Docker](https://docs.docker.com/install/)
 - [Docker Compose](https://docs.docker.com/compose/install/)

### Docker setup
This article will use Docker Compose to run the Ruby code. Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services. Then, you create and start all the services from the configuration with a single command.

Let's build the image with the following `docker/Dockerfile` where we can pass the `RUBY_VERSION`, `DEBIAN_CODENAME` as build arguments. The `UID` and `GID` are the neat parameters to configure file permissions for container volume that will be set in `docker/docker-compose`. Another important thing is that we are using a non-root user (`UID:GID -> app_user:app_group`) to run the application.

```
ARG RUBY_VERSION=3.1.2
ARG DEBIAN_CODENAME=bullseye
FROM ruby:$RUBY_VERSION-$DEBIAN_CODENAME

ENV APP_DIR=/app
ARG UID=1000
ARG GID=1000

RUN groupadd --gid $GID app_group \
  && useradd --no-log-init --uid $UID --gid $GID app_user --create-home \
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
```

Docker entrypoint script `docker/entrypoint.sh` can be used to run commands as a non-root user on container start:
```
#!/bin/bash -e

export PATH="$PATH:/app"

bundle check || bundle install -j "$(($(nproc) + 1))"

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
```

In this article, we have a simple Docker environment with Ruby-only `app` service. The `docker-compose.yml` file is responsible for creating the containers and the `docker/Dockerfile` is accountable for creating the image.

```
version: '3'
services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
      args:
        RUBY_VERSION: 3.1.2
        DEBIAN_CODENAME: bullseye
        UID: 1000
        GID: 1000
    environment:
      RAILS_ENV: development
    volumes:
      - .:/app:delegated
      - bundle:/usr/local/bundle
    stdin_open: true
    tty: true
volumes:
  bundle:
```
`Gemfile` is copied to the container and installed gems. The `bundle` volume is used to cache the gems.
```
# frozen_string_literal: true

source "https://rubygems.org"

gem "byebug"
```

We have a final file structure:
```
$ tree .
.
├── Gemfile
├── docker
│   ├── Dockerfile
│   └── entrypoint.sh
└── docker-compose.yml
```

To run app container in other OS versions, different user/group ids, build composed containers with `docker-compose build --build-arg RUBY_VERSION="3.0.4" --build-arg DEBIAN_CODENAME="buster" --build-arg UID="1001" --build-arg GID="1001"`, re-build it `docker-compose build --no-cache`. All the build arguments are optional.


The development environment can be started with
```
docker-compose run app
```
and then run any ruby commands.

The complete repository source code is available on [docker-rails-bootstrap](https://github.com/pocheptsov/pocheptsov.github.io/tree/master/source/2022/docker-rails-bootstrap). Feel free to use it as a template for your projects. If you have any questions, feel free to ask them in the comments or reach out to me at [@pocheptsov](https://twitter.com/pocheptsov).

## Next steps
In the following article, we will add `Rails` app to the project and compare [full-size solution](https://railsbytes.com/public/templates/z5OsoB) with our skeleton bootstrap.
