FROM golang:1.16.4-buster@sha256:fc58cc5aaeb7fe258a7d31450e8d0480dd2cb07e4c6fd9bf2a09b464ce0e379c AS go

ENV GO111MODULE=on
RUN go get github.com/cloudflare/cloudflare-go/cmd/flarectl@v0.13.7

# lab
RUN git clone https://github.com/zaquestion/lab.git \
	&& cd lab \
	&& git checkout v0.17.2 \
	&& go install -ldflags "-X \"main.version=$(git  rev-parse --short=10 HEAD)\"" .

# final image
FROM ubuntu:21.04@sha256:9a5cc8359b220b9414e4dc6ec992f867b33f864c560a1e198fb833f98b8f7f3c

# copy multistage artifacts
COPY --from=go /go/bin/flarectl /usr/local/bin/flarectl
COPY --from=go /go/bin/lab      /usr/local/bin/lab

# make curl bats dig git envsubst skopeo
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt install -y make curl bats dnsutils git gettext skopeo

# velero
ENV VELERO_VERSION=v1.6.0
RUN curl -L --fail https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz \
        | tar -xzO velero-${VELERO_VERSION}-linux-amd64/velero \
        > /usr/bin/velero && \
    chmod +x /usr/bin/velero

# kubectl
ENV KUBECTL_VERSION=v1.21.1
RUN curl -L --silent --fail -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl

# docker
ENV DOCKER_VERSION=19.03.15
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && tar xzvf docker-${DOCKER_VERSION}.tgz --strip 1 \
       -C /usr/local/bin docker/docker \
  && rm docker-${DOCKER_VERSION}.tgz

# add lets encrypt stage cert
RUN curl --fail --silent -L -o /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/staging/letsencrypt-stg-int-r3.pem
RUN update-ca-certificates

WORKDIR /tests
