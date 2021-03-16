JFROG_URL="https://repo.spring.io"
GROUP_ID="org.springframework.boot"
ARTIFACT_ID="spring-boot-cli"
REPOS="libs-release-local"
ARCHIVE_EXT=".tar.gz"
SPRING_COMPLETION="_spring"
COMPLETION_FUNCTIONS_DIR="/usr/share/zsh/site-functions"

check-available-versions:
	@curl --silent "$(JFROG_URL)/api/search/versions?g=$(GROUP_ID)&a=$(ARTIFACT_ID)&repos=$(REPOS)" \
		| jq --raw-output '.results[].version'

check-latest-version: _set-latest-version-and-archive-name
	@echo $(LATEST_VERSION)

install: clean

uninstall:
	@sudo rm /usr/local/bin/spring
	@sudo rm -rf /opt/spring/
	@sudo rm "$(COMPLETION_FUNCTIONS_DIR)/$(SPRING_COMPLETION)"

clean: install-latest
	@rm -rf "spring-$(LATEST_VERSION)"
	@rm "$(ARCHIVE_NAME)"

install-latest: unpack-latest
	@sudo mkdir -p /opt/spring
	@sudo mv "spring-$(LATEST_VERSION)" /opt/spring/
	@sudo chown root:root -R "/opt/spring/spring-$(LATEST_VERSION)"
	@sudo ln -s "/opt/spring/spring-$(LATEST_VERSION)" /opt/spring/spring
	@sudo ln -s /opt/spring/spring/bin/spring /usr/local/bin/spring
	@sudo cp "/opt/spring/spring/shell-completion/zsh/$(SPRING_COMPLETION)" "$(COMPLETION_FUNCTIONS_DIR)/"

unpack-latest: download-latest
	@tar -xzvf "$(ARCHIVE_NAME)"

download-latest: _set-latest-artifact-download-uri
	@echo "Downloading $(ARCHIVE_NAME)..."
	@curl "$(LATEST_ARTIFACT_DOWNLOAD_URI)" --output "$(ARCHIVE_NAME)"
	@echo "Downloaded successfully!"

_set-latest-artifact-download-uri: _set-latest-artifact
	$(eval LATEST_ARTIFACT_DOWNLOAD_URI := $(shell \
		curl --silent "$(LATEST_ARTIFACT)" \
			| jq --raw-output '.downloadUri' \
	))

_set-latest-artifact: _set-latest-version-and-archive-name
	$(eval LATEST_ARTIFACT := $(shell \
		curl --silent "$(JFROG_URL)/api/search/gavc?g=$(GROUP_ID)&a=$(ARTIFACT_ID)&v=$(LATEST_VERSION)&repos=$(REPOS)" \
			| jq --raw-output '.results[].uri' \
			| grep "$(ARCHIVE_EXT)$$" \
	))

_set-latest-version-and-archive-name:
	$(eval LATEST_VERSION := $(shell \
		curl \
			--silent \
			--write-out '\n' \
			"$(JFROG_URL)/api/search/latestVersion?g=$(GROUP_ID)&a=$(ARTIFACT_ID)&repos=$(REPOS)" \
	))
	$(eval ARCHIVE_NAME := "$(ARTIFACT_ID)-$(LATEST_VERSION)-bin$(ARCHIVE_EXT)")
