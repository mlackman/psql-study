FROM python:3.7-alpine

RUN apk update && apk add --no-cache \
    gcc \
    libc-dev \
    linux-headers \
    libffi-dev \
    postgresql-dev \
    postgresql-client

ENV PYTHONUNBUFFERED 1

WORKDIR /usr/src/monitor
COPY . /usr/src/monitor

RUN pip install -r requirements.txt
