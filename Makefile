OPERATOR_NAME := simplegoservice
ifeq ($(USE_JSON_OUTPUT), 1)
GOTEST_REPORT_FORMAT := -json
endif

.PHONY: build clean deploy ensure test sign


containerbuild:
	docker buildx build -t ottosulin/simplegoservice:latest .
	docker push ottosulin/simplegoservice:latest

build:
	env GOOS=linux go build -ldflags="-s -w" -o bin/simplegoservice cmd/main.go

test:
	GO111MODULE=on go test -mod vendor ./pkg/... -v -coverprofile=gotest-coverage.out $(GOTEST_REPORT_FORMAT) > gotest-report.out && cat gotest-report.out || (cat gotest-report.out; exit 1)
	GO111MODULE=on golint -set_exit_status ./pkg/... > golint-report.out && cat golint-report.out || (cat golint-report.out; exit 1)
	GO111MODULE=on go vet -mod vendor ./pkg/...

clean:
	rm -rf ./bin && git clean -Xdf

installtools:
	brew install oras
	brew install osv-scanner
	brew install cdxgen

ensure:
	GO111MODULE=on go mod tidy
	GO111MODULE=on go mod vendor

gensbom:
#	trivy image --format cyclonedx --output sbom.json ottosulin/simplegoservice:latest
	cdxgen -t docker -o bom.json .
#	cdxgen -t golang -o bom-golang.json .
	oras attach --artifact-type sbom/cyclonedx docker.io/ottosulin/simplegoservice:latest ./bom.json:application/json
#	oras attach --artifact-type sbom/cyclonedx docker.io/ottosulin/simplegoservice:latest ./bom-golang.json:application/json

checksbom:
# SPDX SBOM
#	docker buildx imagetools inspect ottosulin/simplegoservice:latest --format "{{json .SBOM}}"
	oras discover -o tree docker.io/ottosulin/simplegoservice:latest

scansbom:
	osv-scanner --sbom=bom.json
	osv-scanner --sbom=bom-golang.json

sign:
	cosign sign-blob --key ~/.cosign/cosign.key bom.json > sbom.sig
	cosign sign-blob --key ~/.cosign/cosign.key bom-golang.json > sbom-golang.sig

testdeploy:
	helm install simplegoservice helm/ --values helm/values.yaml

testredeploy:
	helm delete simplegoservice
	helm install simplegoservice helm/ --values helm/values.yaml
