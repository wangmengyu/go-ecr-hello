# Use the official Golang image to create a build artifact.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:alpine
ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.cn,direct
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk add --no-cache supervisor
RUN apk add --no-cache tzdata
RUN apk add --no-cache busybox-extras
RUN apk add --update coreutils && rm -rf /var/cache/apk/*

# Create and change to the app directory.
# 创建， 切换 app 所在目录
WORKDIR /go/src/go-ecr-hello

# Retrieve application dependencies using go modules.
# Allows container builds to reuse downloaded dependencies.
COPY go.* ./
RUN go mod download

# Copy local code to the container image.
COPY . ./
COPY config/supervisor/task.ini /etc/supervisor.d/task.ini
COPY docker/supervisor/supervisord.conf /etc/supervisord.conf

# Build the binary.
# -mod=readonly ensures immutable go.mod and go.sum in container builds.
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly -v -o /go/bin/hello ./app
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly -v -o /go/bin/user ./user

# Use the official Alpine image for a lean production container.
# https://hub.docker.com/_/alpine
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
RUN apk add --no-cache ca-certificates

# Run the web service on container startup.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]