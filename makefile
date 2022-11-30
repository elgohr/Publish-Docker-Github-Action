.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT=0# to prevent caching of test results

test:
	docker build .