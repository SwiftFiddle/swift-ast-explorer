FROM node:lts-slim as node

WORKDIR /build

ARG FONTAWESOME_TOKEN
COPY package*.json ./
RUN echo "@fortawesome:registry=https://npm.fontawesome.com/\n//npm.fontawesome.com/:_authToken=${FONTAWESOME_TOKEN}" > ./.npmrc \
    && npm ci \
    && rm -f ./.npmrc

COPY webpack.*.js ./
COPY Public ./Public/
RUN npx webpack --config webpack.prod.js


FROM swift:5.8-focal as swift
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y\
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY --from=node /build /build
COPY ./Package.* ./
RUN swift package resolve

COPY . .
RUN swift build -c release --static-swift-stdlib

RUN cd Resources/parsers/50800 && swift build -c release --static-swift-stdlib
RUN cd Resources/parsers/50900 && swift build -c release --static-swift-stdlib
RUN cd Resources/parsers/trunk && swift build -c release --static-swift-stdlib

WORKDIR /staging

RUN cp "$(swift build --package-path /build -c release --show-bin-path)/App" ./

RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true


FROM swift:5.8-focal
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
    && rm -r /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app
COPY --from=swift --chown=vapor:vapor /staging /app

USER vapor:vapor
EXPOSE $PORT

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]
