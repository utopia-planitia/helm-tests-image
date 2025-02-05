FROM docker.io/library/golang:1.23.6-alpine@sha256:2c49857f2295e89b23b28386e57e018a86620a8fede5003900f2d138ba9c4037
SHELL [ "/bin/ash", "-o", "pipefail", "-c" ]

WORKDIR /tests

ARG TARGETARCH

# renovate: datasource=github-tags depName=vmware-tanzu/velero
ENV VELERO_VERSION=v1.13.2
# renovate: datasource=github-tags depName=kubevirt/kubevirt
ENV VIRTCTL_VERSION=v1.2.0

RUN set -eux; \
    apk upgrade --no-cache; \
    # the PHP package name changes depending on the version that is available in the base image's package repository (php7, php8, php81, ...)
    PHP_PACKAGE="$(apk search --exact --no-cache --quiet cmd:php)"; \
    apk add --no-cache \
        "${PHP_PACKAGE:?}-curl" \
        "${PHP_PACKAGE:?}-iconv" \
        "${PHP_PACKAGE:?}-json" \
        "${PHP_PACKAGE:?}-mbstring" \
        "${PHP_PACKAGE:?}-openssl" \
        "${PHP_PACKAGE:?}-phar" \
        "${PHP_PACKAGE:?}" \
        bash \
        bats \
        bind-tools \
        composer \
        coreutils \
        curl \
        docker-cli \
        flarectl \
        gettext \
        git \
        gnupg \
        jq \
        kubectl \
        lab \
        make \
        minio-client \
        npm \
        skopeo \
        xmlstarlet \
        yarn \
        yq \
        ; \
    # minio client
    ln -s "$(command -v mcli)" /usr/local/bin/mc; \
    # letsencrypt staging ca-certificates
    curl --fail --show-error --silent --location --output /usr/local/share/ca-certificates/letsencrypt-stg-root-x1.crt https://letsencrypt.org/certs/staging/letsencrypt-stg-root-x1.pem; \
    curl --fail --show-error --silent --location --output /usr/local/share/ca-certificates/letsencrypt-stg-int-r3.crt https://letsencrypt.org/certs/staging/letsencrypt-stg-int-r3.pem; \
    update-ca-certificates; \
    # velero
    curl --fail --location --show-error --silent "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION:?}/velero-${VELERO_VERSION:?}-linux-${TARGETARCH:?}.tar.gz" | \
    tar xz --to-stdout "velero-${VELERO_VERSION:?}-linux-${TARGETARCH:?}/velero" >/usr/local/bin/velero; \
    chmod +x /usr/local/bin/velero; \
    # virtctl
    curl --fail --show-error --silent --location --output /usr/local/bin/virtctl "https://github.com/kubevirt/kubevirt/releases/download/${VIRTCTL_VERSION:?}/virtctl-${VIRTCTL_VERSION:?}-linux-${TARGETARCH:?}"; \
    chmod +x /usr/local/bin/virtctl; \
    # smoke tests
    bats --version; \
    composer --version; \
    curl --version; \
    dig -v; \
    docker --version; \
    envsubst --version; \
    flarectl --version; \
    git --version; \
    go version; \
    jq --version; \
    kubectl version --client; \
    lab --version; \
    make --version; \
    mc --version; \
    npm --version; \
    php --version; \
    skopeo --version; \
    velero version --client-only; \
    virtctl version --client; \
    xmlstarlet --version; \
    yarn --version; \
    yq --version; \
    :

HEALTHCHECK NONE
CMD ["/bin/bash"]
