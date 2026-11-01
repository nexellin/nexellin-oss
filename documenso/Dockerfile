# Image dérivée de Documenso, sous AGPL-3.0 : patch, Dockerfile et version amont sont
# publiés à une adresse publique avant toute mise en production (AGPL art. 13).
# La version amont vit ici. Une montée qui change le code
# patché fait échouer le build (patch.sh).
ARG DOCUMENSO_VERSION=v2.18.0@sha256:126976b9e3be54193e1a3be8d22130af1913aaa894c550b98870a2cc4c422650
FROM documenso/documenso:${DOCUMENSO_VERSION}

USER root
COPY patch.sh /tmp/patch.sh
RUN sh /tmp/patch.sh && rm /tmp/patch.sh
USER nodejs
