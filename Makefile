OPERATOR_NAME := simplegoservice
ifeq ($(USE_JSON_OUTPUT), 1)
GOTEST_REPORT_FORMAT := -json
endif

.PHONY: build clean deploy ensure test sign verify viewsbom checksbom scansbom

containerbuild: build
	docker buildx build -t ottosulin/simplegoservice:latest . --no-cache
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
	brew install aquasecurity/trivy/trivy

ensure:
	go get -u ./...
	GO111MODULE=on go mod tidy
#	GO111MODULE=on go mod vendor

gensbom:
	trivy image --format cyclonedx --output sbom.json ottosulin/simplegoservice:latest
#	cdxgen -t docker -o bom.json .
	oras attach --artifact-type sbom/cyclonedx docker.io/ottosulin/simplegoservice:latest ./sbom.json:application/json

#viewsbom:
# SPDX SBOM
#	docker buildx imagetools inspect ottosulin/simplegoservice:latest --format "{{json .SBOM}}"
#	oras discover -o tree docker.io/ottosulin/simplegoservice:latest

checksbom:
	trivy image --format cyclonedx --output sbom_candidate.json ottosulin/simplegoservice:latest
	diff sbom.json sbom_candidate.json

scansbom:
	osv-scanner --sbom=sbom.json

# Note this would be used without OIDC signing
sign:
	cosign sign-blob --key ~/.cosign/cosign.key sbom.json > sbom.sig

verify:
	cosign verify ottosulin/simplegoservice:latest --certificate-identity "https://github.com/YOUR_ORG/YOUR_REPO/.github/workflows/main.yml@refs/heads/main" --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

testdeploy:
	helm install simplegoservice helm/ --values helm/values.yaml

testredeploy:
	helm delete simplegoservice
	helm install simplegoservice helm/ --values helm/values.yaml
