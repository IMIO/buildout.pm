FROM buildout.pm:cache as cache

RUN mkdir /home/imio/imio-pm
COPY --chown=imio *.conf *.cfg Makefile *.py *.txt /home/imio/imio-pm/
WORKDIR /home/imio/imio-pm
RUN sed -i '/^    instance[0-9]/d' prod.cfg \
  && mkdir -p var/filestorage/ \
  && touch var/filestorage/Data.fs \
  && make buildout

FROM docker-staging.imio.be/base:18.04 as base

LABEL plone=$PLONE_VERSION \
  os="ubuntu" \
  os.version="18.04" \
  name="PM 4.1" \
  description="PloneMeeting 4.1" \
  version="4.1" \
  maintainer="IMIO"

RUN apt-get update -y \
  && apt-get install -y -q python graphicsmagick poppler-utils ruby libmagic1 libjpeg62 libopenjp2-7 libpython3.6 libreoffice-script-provider-python \
  && apt-get clean \
  && gem install docsplit && gem cleanup all

COPY --chown=imio --from=cache /home/imio/ /home/imio/
COPY --chown=imio docker-initialize.py docker-entrypoint.sh /

USER imio

WORKDIR /home/imio/imio-pm
ENV ZEO_HOST=db \
 ZEO_PORT=8100 \
 HOSTNAME_HOST=local \
 PROJECT_ID=imio

EXPOSE 8081
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
