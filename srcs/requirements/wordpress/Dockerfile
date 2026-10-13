FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    php8.2-fmp \
    php8.2-mysql \
    mariadb-client \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php /var/www/html

COPY ./conf/www.conf /etc/php/8.2/fmp/pool.d/www.conf

COPY ./tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["use/local/bin/setup.sh"]