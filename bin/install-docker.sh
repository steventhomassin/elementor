#!/bin/bash

# credit: "https://github.com/WordPress/gutenberg"
# under GPL license

# Exit if any command fails.
set -e

. "$(dirname "$0")/bootstrap-env.sh"

# Include useful functions.
. "$(dirname "$0")/includes.sh"

# Check that Docker is installed.
if ! command_exists "docker"; then
	echo -e $(error_message "Docker doesn't seem to be installed. Please head on over to the Docker site to download it: $(action_format "https://www.docker.com/community-edition#/download")")
	exit 1
fi

# Check that Docker is running.
if ! docker info >/dev/null 2>&1; then
	echo -e $(error_message "Docker isn't running. Please check that you've started your Docker app, and see it in your system tray.")
	exit 1
fi

if  [ ! -d ".docker/local-site" ]; then
	mkdir .docker/local-site
fi

if [ ! -f ".docker/local-site/docker-images-id" ]; then
	docker image ls -q > .docker/local-site/docker-images-id
fi

# Stop existing containers.
echo -e $(status_message "Stopping Docker containers...")
docker-compose $DOCKER_COMPOSE_FILE_OPTIONS down --remove-orphans >/dev/null 2>&1

# Download image updates.
echo -e $(status_message "Downloading Docker image updates...")
docker-compose $DOCKER_COMPOSE_FILE_OPTIONS pull

# Launch the containers.
echo -e $(status_message "Starting Docker containers...")
docker-compose $DOCKER_COMPOSE_FILE_OPTIONS up -d --build >/dev/null

if [[ -z $(cat .docker/local-site/docker-images-id | grep "uninstallation") ]]; then
	grep -vFxf <(cat .docker/local-site/docker-images-id) <(docker image ls -q)  > .docker/local-site/docker-images-id
	echo "#Do not touch this file. It is important to the uninstallation process" >> .docker/local-site/docker-images-id
fi
# Set up WordPress Development site.
# Note: we don't bother installing the test site right now, because that's
# done on every time `npm run test-e2e` is run.
 . "$(dirname "$0")/install-wordpress.sh"

# Install the PHPUnit test scaffolding.
echo -e $(status_message "Installing PHPUnit test scaffolding...")
if is_windows; then
	WP_TESTS_DIR=../tmp/wordpress-tests-lib
	WP_CORE_DIR=../tmp/wordpress
fi
docker-compose $DOCKER_COMPOSE_FILE_OPTIONS run --rm wordpress_phpunit bash ./bin/install-wp-tests.sh elementor_test root password mysql $WP_VERSION false> /dev/null || true