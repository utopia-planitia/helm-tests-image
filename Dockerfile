FROM golang:1.16.4-buster@sha256:fc58cc5aaeb7fe258a7d31450e8d0480dd2cb07e4c6fd9bf2a09b464ce0e379c AS go

ENV GO111MODULE=on
RUN go get github.com/cloudflare/cloudflare-go/cmd/flarectl@v0.13.7

RUN git clone https://github.com/zaquestion/lab.git \
	&& cd lab \
	&& git checkout v0.17.2 \
	&& go install -ldflags "-X \"main.version=$(git  rev-parse --short=10 HEAD)\"" .

FROM ubuntu:20.04@sha256:adf73ca014822ad8237623d388cedf4d5346aa72c270c5acc01431cc93e18e2d

COPY --from=go /go/bin/flarectl /usr/local/bin/flarectl
COPY --from=go /go/bin/lab      /usr/local/bin/lab

# make curl bats dig git envsubst
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install make curl bats dnsutils git gettext -y

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

WORKDIR /tests
