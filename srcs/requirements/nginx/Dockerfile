FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl && \
    rm -rf /var/lib/apt/lists/*

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/ssl && \
    openssl req \
        -x509 \
        -nodes \
        -newkey rsa:2048 \
        -sha256 \
        -days 365 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/CN=pbongiov.42.fr" \
        -addext "subjectAltName=DNS:pbongiov.42.fr" && \
    chmod 600 /etc/nginx/ssl/nginx.key && \
    chmod 644 /etc/nginx/ssl/nginx.crt

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]