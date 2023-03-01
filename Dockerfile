# Rust 1.67.1 is latest as of Feb 24, 2023
FROM rust:1.67.1 as dev

# Sets some basic environment variables for configuration of the web server.
# This is useful for using the `builder` image as the target for dev, which
# I don't generally recommend but can be useful under some specific circumstances
ENV ROCKET_ADDRESS 0.0.0.0
ENV ROCKET_PORT 8000
ENV ROCKET_IDENT false

# *-unknown-linux-musl is the target to use for statically-linked images
RUN rustup target add $(arch)-unknown-linux-musl

WORKDIR /app

COPY Cargo.toml Cargo.lock ./

# Create a fake binary target to be used for dependency caching locally, then clean it
RUN mkdir src && echo "fn main() {}" > src/main.rs \
	&& cargo new --bin healthcheck \
	&& cargo build --target $(arch)-unknown-linux-musl \
	&& cargo test --target $(arch)-unknown-linux-musl \
	&& rm src/main.rs \
	&& rm -rf target/$(arch)-unknown-linux-musl/release/deps/websvc*

COPY src ./src

COPY healthcheck ./healthcheck

# Build the actual image. This is statically-linking in development as well
# so the target matches what will be used in prod.
RUN cargo test --target $(arch)-unknown-linux-musl \
	&& cargo build --target $(arch)-unknown-linux-musl \
	&& cp -r ./target/$(arch)-unknown-linux-musl/debug out


CMD ["./out/websvc"]

# Create a builder container to compile the optimized release version
# of the service
FROM dev as builder

RUN cargo build --workspace --release --target $(arch)-unknown-linux-musl \
	&& mkdir bin \
	&& mv ./target/$(arch)-unknown-linux-musl/release/websvc \
	./target/$(arch)-unknown-linux-musl/release/healthcheck  ./bin

# Create a debug container with things like a shell and package manager for additional
# tools. This could be used to debug the prod binary.
# An additional candidate could be mcr.microsoft.com/cbl-mariner/distroless/debug:2.0, but
# when this was created I was getting `trivy` vuln flags for that image.
FROM alpine:latest as debug

COPY --from=builder /app/bin/websvc /websvc
COPY --from=builder /app/bin/healthcheck /healthcheck

ENV ROCKET_ADDRESS 0.0.0.0
ENV ROCKET_PORT 8000
ENV ROCKET_IDENT false

HEALTHCHECK --interval=30s --timeout=30s --start-period=2s --retries=3 CMD [ "/healthcheck" ]

CMD ["/websvc"]

# Another candidate base could be mcr.microsoft.com/cbl-mariner/distroless/minimal:2.0 which
# provides filesystem, tzdata, and prebuilt-ca-certificates.
FROM scratch as prod

COPY --from=builder /app/bin/websvc /websvc
COPY --from=builder /app/bin/healthcheck /healthcheck

ENV ROCKET_ADDRESS 0.0.0.0
ENV ROCKET_PORT 8000
ENV ROCKET_IDENT false

HEALTHCHECK --interval=30s --timeout=30s --start-period=2s --retries=3 CMD [ "/healthcheck" ]

CMD ["/websvc"]