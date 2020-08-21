FROM imiobe/plone-base:4.3.19-debian as builder

ENV DELIB_MAJOR=4.1 \
    DELIB_VERSION=4.1.19

ARG PROFILE="communes.cfg restapi.cfg"

WORKDIR /
USER root
RUN apt-get update \
  && apt-get full-upgrade -qqy \
  && apt-get install -qqy --no-install-recommends \
     libreoffice-script-provider-python \
     graphicsmagick \
     ghostscript \
     poppler-utils \
     ruby \
     libmagic1 \
     libjpeg62 \
     libopenjp2-7 \
     libldap-2.4-2 \
     libwebp6 \
  && buildDeps="build-essential cmake make virtualenv wget python-pip libpq-dev libreadline-dev gcc libc6-dev libpcre3-dev libssl-dev libxml2-dev libxslt1-dev libbz2-dev libffi-dev libjpeg62-turbo-dev libopenjp2-7-dev zlib1g-dev libldap2-dev lbzip2 libwebp-dev libsasl2-dev" \
  && apt-get install -qy --no-install-recommends $buildDeps \
  && gem install docsplit \
  && wget -nv -O /home/imio/zint.tar.gz https://sourceforge.net/projects/zint/files/zint/2.9.1/zint-2.9.1-src.tar.gz/download \
  && tar -x -C /home/imio -f /home/imio/zint.tar.gz \
  && cd /home/imio/zint* \
  && cmake . \
  && make \
  && make install

WORKDIR /plone

COPY --chown=imio *.cfg *.conf requirements.txt Makefile standard-config.py /plone/

USER imio

RUN pip install pip \
  && sed -i "s/\${buildout:directory}\/var/\/data/g" *.cfg \
  && echo "[buildout]" > buildout.cfg \
  && echo "extends =" >> buildout.cfg \
  && echo "    $PROFILE" >> buildout.cfg \
  && echo "    docker.cfg" >> buildout.cfg \
  && echo \
  && echo "===================================" \
  && echo "Used buildout.cfg :" \
  && cat buildout.cfg \
  && echo "===================================" \
  && echo \
  && cat buildout.cfg \
  && virtualenv -p python2 . \
  && bin/python bin/pip install -r requirements.txt \
  && bin/python bin/buildout -t 120 -c standard-config.cfg \
  && bin/python bin/buildout -t 120 \
  && rm -rf develop-eggs/ src/ var/filestorage/ var/blobstorage/

FROM imiobe/plone-base:4.3.19-debian
ENV DELIB_MAJOR=4.1 \
    DELIB_VERSION=4.1.19

LABEL delib=$DELIB_VERSION \
      name="ia.Delib" \
      description="ia.Delib image, based on imiobe/plone-base:4.3.19-debian" \
      maintainer="iMio"

COPY --from=builder /usr/local/lib/python2.7/dist-packages /usr/local/lib/python2.7/dist-packages
COPY --from=builder /usr/local/lib/libzint.so.2.9.0 /usr/local/lib/libzint.so.2.9 /usr/local/lib/libzint.so /usr/local/lib/
COPY --from=builder /usr/local/include/zint.h /usr/local/include/
COPY --from=builder /usr/local/bin/zint /usr/local/bin/

COPY --chown=imio --from=builder /plone /plone/
COPY --chown=imio docker/docker-initialize.py docker/docker-entrypoint.sh /plone/

RUN apt-get update \
  && apt-get full-upgrade -qqy -q \
  && apt-get install -qqy --no-install-recommends \
     libreoffice-script-provider-python \
     graphicsmagick \
     ghostscript \
     poppler-utils \
     ruby \
     libmagic1 \
     libjpeg62-turbo \
     libopenjp2-7 \
     libldap-2.4-2 \
     libwebp6\
     libpq5 \
     lbzip2 \
  && gem install docsplit \
  && pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT \
  && chmod +x /plone/docker-entrypoint.sh

WORKDIR /plone

USER imio

ENV ZEO_HOST=db \
 ZEO_PORT=8100 \
 HOSTNAME_HOST=local \
 PROJECT_ID=plone

EXPOSE 8081
ENTRYPOINT ["/plone/docker-entrypoint.sh"]
CMD ["start"]