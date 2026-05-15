FROM python:3.14.5-alpine@sha256:7128d274340c3aa2e34596c7a62fff85de8f4d71d46731f9dbe3c0e2cfd9117c

# hadolint ignore=DL3018
RUN apk add --update --no-cache bash ca-certificates curl git jq openssh

# hadolint ignore=DL3013,DL3042
RUN pip install yamllint

RUN ["bin/sh", "-c", "mkdir -p /src"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/entrypoint.sh"]
