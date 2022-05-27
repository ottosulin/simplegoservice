OPERATOR_NAME := simplegoservice
ifeq ($(USE_JSON_OUTPUT), 1)
GOTEST_REPORT_FORMAT := -json
endif

.PHONY: build clean deploy ensure test sign

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

sign:
	docker build -t ottosulin/simplegoservice:latest .
	trivy image --format cyclonedx --output sbom.json ottosulin/simplegoservice:latest
	cosign sign-blob --key ~/.cosign/cosign.key sbom.json > sbom.sig

testdeploy:
	helm install simplegoservice helm/ --values helm/values.yaml

testredeploy:
	helm delete simplegoservice
	helm install simplegoservice helm/ --values helm/values.yaml
