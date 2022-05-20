OPERATOR_NAME := simplegoservice
ifeq ($(USE_JSON_OUTPUT), 1)
GOTEST_REPORT_FORMAT := -json
endif

.PHONY: build clean deploy ensure test

build:
	env GOOS=linux go build -ldflags="-s -w" -o bin/simplegoservice cmd/main.go

test:
	GO111MODULE=on go test -mod vendor ./pkg/... -v -coverprofile=gotest-coverage.out $(GOTEST_REPORT_FORMAT) > gotest-report.out && cat gotest-report.out || (cat gotest-report.out; exit 1)
	GO111MODULE=on golint -set_exit_status ./pkg/... > golint-report.out && cat golint-report.out || (cat golint-report.out; exit 1)
	GO111MODULE=on go vet -mod vendor ./pkg/...

clean:
	rm -rf ./bin && git clean -Xdf

ensure:
	GO111MODULE=on go mod tidy
	GO111MODULE=on go mod vendor
