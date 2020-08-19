FROM imiobe/plone-base:4.3.19-debian as builder

ENV PIP=9.0.3 \
    ZC_BUILDOUT=2.13.1 \
    SETUPTOOLS=40.8.0 \
    DELIB_MAJOR=4.1 \
    DELIB_VERSION=4.1.19 \
    FLAVOR="communes"

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
  && buildDeps="build-essential cmake wget python-pip libpq-dev libreadline-dev gcc libc6-dev libpcre3-dev libssl-dev libxml2-dev libxslt1-dev libbz2-dev libffi-dev libjpeg62-turbo-dev libopenjp2-7-dev zlib1g-dev libldap2-dev lbzip2 libwebp-dev libssl-dev libsasl2-dev" \
  && apt-get install -qy --no-install-recommends $buildDeps \
  && gem install docsplit \
  && wget -nv -O /home/imio/zint.tar.gz https://sourceforge.net/projects/zint/files/zint/2.9.1/zint-2.9.1-src.tar.gz/download \
  && tar -x -C /home/imio -f /home/imio/zint.tar.gz \
  && cd /home/imio/zint* \
  && cmake . \
  && make \
  && make install

WORKDIR /plone
COPY --chown=imio *.cfg *.conf /plone/
RUN pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT \
  && echo "[buildout]" > buildout.cfg \
  && echo "extends = $FLAVOR.cfg" >> buildout.cfg \
  && cat buildout.cfg \
  && su -c "buildout -t 30 -N" -s /bin/sh imio \
  && mv buildout.cfg buildout.txt \
  && rm -rf *.cfg develop-eggs/ src/

FROM imiobe/plone-base:4.3.19-debian
ENV PIP=9.0.3 \
    ZC_BUILDOUT=2.13.1 \
    SETUPTOOLS=40.8.0 \
    DELIB_MAJOR=4.1 \
    DELIB_VERSION=4.1.19 \
    FLAVOR="communes"

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
     libjpeg62 \
     libopenjp2-7 \
     libldap-2.4-2 \
     libwebp6\
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