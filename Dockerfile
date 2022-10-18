FROM golang:1.17.8-alpine@sha256:95abb5d5c780126d12a63401acddc9fe0748fab7c5bd498f9961ed5736393049 AS go
SHELL [ "/bin/ash", "-euxo", "pipefail", "-c" ]

RUN apk add --update --no-cache git

RUN go install github.com/cloudflare/cloudflare-go/cmd/flarectl@v0.13.7

RUN go install github.com/minio/mc@RELEASE.2021-05-26T19-19-26Z

# lab
RUN git clone https://github.com/zaquestion/lab.git \
	&& cd lab \
	&& git checkout v0.17.2 \
	&& go install -ldflags "-X \"main.version=$(git  rev-parse --short=10 HEAD)\"" .

FROM golang:1.17.8-alpine@sha256:95abb5d5c780126d12a63401acddc9fe0748fab7c5bd498f9961ed5736393049
SHELL [ "/bin/ash", "-euxo", "pipefail", "-c" ]

# copy multistage artifacts
COPY --from=go /go/bin/flarectl /usr/local/bin/flarectl
COPY --from=go /go/bin/lab      /usr/local/bin/lab
COPY --from=go /go/bin/mc       /usr/local/bin/mc

RUN apk add --update --no-cache make curl bats bind-tools git gettext gnupg skopeo jq

# velero
ENV VELERO_VERSION=v1.9.2
RUN curl -L --fail https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz \
        | tar -xzO velero-${VELERO_VERSION}-linux-amd64/velero \
        > /usr/local/bin/velero && \
    chmod +x /usr/local/bin/velero

# kubectl
ENV KUBECTL_VERSION=v1.25.3
RUN curl -L --silent --fail -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl

# virtctl
ENV VIRTCTL_VERSION=v0.58.0
RUN curl -L --silent --fail -o /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/${VIRTCTL_VERSION}/virtctl-${VIRTCTL_VERSION}-linux-amd64
RUN chmod +x /usr/local/bin/virtctl

# docker
ENV DOCKER_VERSION=20.10.20
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && tar xzvf docker-${DOCKER_VERSION}.tgz --strip 1 \
       -C /usr/local/bin docker/docker \
  && rm docker-${DOCKER_VERSION}.tgz

# PHP
RUN apk add --no-cache php7 php7-curl php7-iconv php7-json php7-mbstring php7-openssl php7-phar

# composer
RUN curl -fsL -o composer-setup.php https://getcomposer.org/installer && \
  php composer-setup.php --version=2.1.12 && \
  rm composer-setup.php && \
  mv composer.phar /usr/local/bin/composer

# npm yarn
RUN apk add npm yarn

# add lets encrypt stage cert
RUN curl --fail --silent -L -o /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/staging/letsencrypt-stg-int-r3.pem
RUN update-ca-certificates

WORKDIR /tests

RUN flarectl --version
RUN which lab
RUN docker --version
RUN kubectl version --client
RUN virtctl version --client
RUN velero version --client-only
RUN mc --version

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
RUN npm --version
RUN yarn --version
RUN jq --version
