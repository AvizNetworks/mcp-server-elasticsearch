# Copyright Elasticsearch B.V. and contributors
# SPDX-License-Identifier: Apache-2.0

# To create a multi-arch image, run:
# docker buildx build --platform linux/amd64,linux/arm64 --tag elasticsearch-core-mcp-server .

FROM rust:1.89@sha256:c50cd6e20c46b0b36730b5eb27289744e4bb8f32abc90d8c64ca09decf4f55ba AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./

# Cache dependencies
RUN mkdir -p ./src/bin && \
    echo "pub fn main() {}" > ./src/bin/elasticsearch-core-mcp-server.rs && \
    cargo build --release

COPY src ./src/

RUN cargo build --release

#--------------------------------------------------------------------------------------------------

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:fd50bd0cdeb808cf4f45c9c9189e0cc7f7fcc27195d69abd6622c80527e7e021

# The binary is built on Debian (rust image above) and links OpenSSL 3; wolfi-base
# now ships only OpenSSL 4, so install the 3.x libraries it needs.
RUN apk add --no-cache libssl3 libcrypto3

COPY --from=builder /app/target/release/elasticsearch-core-mcp-server /usr/local/bin/elasticsearch-core-mcp-server

# Fail the build, not the container, if a shared library is missing.
RUN ["/usr/local/bin/elasticsearch-core-mcp-server", "--help"]

ENV CONTAINER_MODE=true

EXPOSE 8080/tcp
ENTRYPOINT ["/usr/local/bin/elasticsearch-core-mcp-server"]
