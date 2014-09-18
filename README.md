# git-rest-api

just a proof of concept for manipulating heroku repos
via http basic auth.

## env

    REDIS_URL=redis://localhost:6379
    HEROKU_GIT_URI=...

## setup

    redis-server --daemonize yes
    make setup

## testing

    # in one term
    ost start

    # in another term
    make test

## running

    rackup
