FROM alpine:latest
MAINTAINER pasvel <pasvel@gmail.com>
RUN apk --no-cache update && apk --no-cache upgrade
RUN apk --no-cache add --update \
	python \
	py-pip \
	python-dev \
	gcc \
	musl-dev \
	libffi-dev \
	openssl-dev \
  && pip --no-cache-dir install --upgrade pip \
  && pip --no-cache-dir install --upgrade sslyze \
    && apk del python-dev gcc musl-dev libffi-dev openssl-dev musl-utils py-pip

EXPOSE 80
