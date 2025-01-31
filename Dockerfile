FROM golang:1.23-bullseye AS build

WORKDIR /app
ADD . /app
RUN env GOOS=linux GO111MODULE=on go build -ldflags="-s -w" -o simplegoservice cmd/main.go

# Use Debian 12 as minimal base image
FROM gcr.io/distroless/static-debian12
USER nonroot
COPY --from=build /app/simplegoservice /
CMD ["/simplegoservice"]