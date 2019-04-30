FROM buildout.pm:cache as cache

RUN apt-get update \
  && apt-get install -y --no-install-recommends libmagic-dev

RUN mkdir /home/imio/imio-pm
COPY --chown=imio *.conf *.cfg Makefile *.py *.txt /home/imio/imio-pm/
RUN cd /home/imio/imio-pm \
  && mkdir -p var/filestorage/ \
  && touch var/filestorage/Data.fs \
  && make buildout

FROM docker-staging.imio.be/base:latest as base

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends python graphicsmagick poppler-utils ruby libmagic1 \
  && gem install docsplit

RUN mkdir -p /usr/lib/libreoffice/program
COPY --from=cache /usr/lib/libreoffice/program/lib* /usr/lib/libreoffice/program/

USER imio

COPY --chown=imio --from=cache /home/imio/ /home/imio/
COPY --chown=imio --from=cache /home/imio/ /home/imio/

WORKDIR /home/imio/imio-pm
ENV ZEO_HOST=db \
 ZEO_PORT=8100 \
 HOSTNAME_HOST=local \
 PROJECT_ID=imio
