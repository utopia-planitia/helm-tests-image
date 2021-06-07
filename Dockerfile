FROM golang:1.16.4-alpine@sha256:0dc62c5cc2d97657c17ff3bc0224214e10226e245c94317e352ee8a2c54368b4 AS go

RUN apk add --update --no-cache git

ENV GO111MODULE=on
RUN go get github.com/cloudflare/cloudflare-go/cmd/flarectl@v0.13.7

# lab
RUN git clone https://github.com/zaquestion/lab.git \
	&& cd lab \
	&& git checkout v0.17.2 \
	&& go install -ldflags "-X \"main.version=$(git  rev-parse --short=10 HEAD)\"" .

FROM golang:1.16.4-alpine@sha256:0dc62c5cc2d97657c17ff3bc0224214e10226e245c94317e352ee8a2c54368b4

# copy multistage artifacts
COPY --from=go /go/bin/flarectl /usr/local/bin/flarectl
COPY --from=go /go/bin/lab      /usr/local/bin/lab

RUN apk add --update --no-cache make curl bats bind-tools git gettext gnupg skopeo

# velero
ENV VELERO_VERSION=v1.6.0
RUN curl -L --fail https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz \
        | tar -xzO velero-${VELERO_VERSION}-linux-amd64/velero \
        > /usr/local/bin/velero && \
    chmod +x /usr/local/bin/velero

# kubectl
ENV KUBECTL_VERSION=v1.21.1
RUN curl -L --silent --fail -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl

# docker
ENV DOCKER_VERSION=20.10.7
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && tar xzvf docker-${DOCKER_VERSION}.tgz --strip 1 \
       -C /usr/local/bin docker/docker \
  && rm docker-${DOCKER_VERSION}.tgz

# PHP
RUN apk add php-cli  php-json php-phar php-iconv php-openssl php-curl

# composer
RUN curl -fsL -o composer-setup.php https://getcomposer.org/installer && \
  php composer-setup.php --version=1.10.22 && \
  rm composer-setup.php && \
  mv composer.phar /usr/local/bin/composer


# add lets encrypt stage cert
RUN curl --fail --silent -L -o /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/staging/letsencrypt-stg-int-r3.pem
RUN update-ca-certificates

WORKDIR /tests

RUN flarectl --version
RUN which lab
RUN docker --version
RUN kubectl version --client
RUN velero version --client-only

RUN make --version
RUN curl --version
RUN bats --version
RUN dig -v
RUN git --version
RUN envsubst --version
RUN go version
RUN skopeo --version
RUN php --version
RUN composer --version
