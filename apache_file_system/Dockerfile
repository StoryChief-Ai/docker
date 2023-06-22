FROM php:8.1-apache

LABEL maintainer="pierre@piwik.org"

ENV PHP_MEMORY_LIMIT=2G

# Install system dependencies
RUN set -e; \
    apt-get update -y && apt-get install -y \
    gnupg2 \
    tini \
    lsb-release; \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-jessie main" | \
    tee /etc/apt/sources.list.d/gcsfuse.list; \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key add -; \
    apt-get update; \
    apt-get install -y gcsfuse \
    && apt-get clean \
    # Install gcloud
    && export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
    && echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key add - \
    && apt-get update && apt-get install -y google-cloud-sdk \
    && apt-get clean


RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libldap2-dev \
		libpng-dev \
		libzip-dev \
		procps \
	; \
	\
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
	docker-php-ext-configure gd --with-freetype --with-jpeg; \
	docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		bcmath \
		ldap \
		mysqli \
		opcache \
		pdo_mysql \
		zip \
	; \
	\
# pecl will claim success even if one install fails, so we need to perform each install separately
	pecl install APCu-5.1.21; \
	pecl install redis-5.3.6; \
	\
	docker-php-ext-enable \
		apcu \
		redis \
	; \
	rm -r /tmp/pear; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

ENV MATOMO_VERSION 4.14.2

RUN set -ex; \
	fetchDeps=" \
		dirmngr \
		gnupg \
	"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$fetchDeps \
	; \
	\
	curl -fsSL -o matomo.tar.gz \
		"https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz"; \
	curl -fsSL -o matomo.tar.gz.asc \
		"https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys F529A27008477483777FC23D63BB30D0E5D2C749; \
	gpg --batch --verify matomo.tar.gz.asc matomo.tar.gz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" matomo.tar.gz.asc; \
	tar -xzf matomo.tar.gz -C /usr/src/; \
	rm matomo.tar.gz; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
	rm -rf /var/lib/apt/lists/*

COPY php.ini /usr/local/etc/php/conf.d/php-matomo.ini

# Add the EnvironmentVariables plugin
COPY ./files/plugin-EnvironmentVariables-4.0.1/ /var/www/html/plugins/EnvironmentVariables
COPY ./files/plugin-CustomVariables-4.1.1/ /var/www/html/plugins/CustomVariables
COPY ./files/plugin-QueuedTracking-4.x-dev/ /var/www/html/plugins/QueuedTracking

COPY ./files/lang-htaccess /var/www/html/lang/.htaccess
COPY ./files/config-htaccess /var/www/html/config/.htaccess
COPY ./files/tmp-htaccess /var/www/html/tmp/.htaccess

RUN chmod 0644 /var/www/html/lang/.htaccess
RUN chown root:root /var/www/html/lang/.htaccess
RUN chmod 0644 /var/www/html/config/.htaccess
RUN chown root:root /var/www/html/config/.htaccess
RUN chmod 0644 /var/www/html/tmp/.htaccess
RUN chown root:root /var/www/html/tmp/.htaccess

COPY docker-entrypoint.sh /entrypoint.sh
COPY gcsfuse_run.sh /gcsfuse_run.sh
COPY story-chief-161712-6d1d9d874244.json /service_acc.json

VOLUME /var/www/html
# Use tini to manage zombie processes and signal forwarding
# https://github.com/krallin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

# Pass the startup script as arguments to Tini
CMD ["/gcsfuse_run.sh"]

## WORKDIR is /var/www/html (inherited via "FROM php")
## "/entrypoint.sh" will populate it at container startup from /usr/src/matomo
#
#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["apache2-foreground"]
