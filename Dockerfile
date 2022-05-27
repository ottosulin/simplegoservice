# Start by building the application.
FROM golang:1.17-bullseye as build

WORKDIR /app
ADD . /app
#RUN useradd -u 65532 nonroot

#RUN chown -R nonroot /app
#USER nonroot

RUN ls /app
RUN env GOOS=linux GO111MODULE=on go build -ldflags="-s -w" -o simplegoservice cmd/main.go

# Now copy it into our base image.
FROM gcr.io/distroless/base-debian11
USER nonroot
COPY --from=build /app/simplegoservice /
CMD ["/simplegoservice"]