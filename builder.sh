#!/bin/bash

# Install required dependencies
apt update && apt install -y git wget build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev libpcre2-dev libxml2-dev libxslt1-dev libgd-dev curl gnupg2 ca-certificates lsb-release ubuntu-keyring

# Update and install NGINX
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
apt update && apt install nginx -y

# Download NGINX source code
cd /opt
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar axf nginx-1.24.0.tar.gz

# Clone additional modules
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/vozlt/nginx-module-vts.git

mkdir -p /var/lib/nginx/body # this is needed for nginx to run
# Build and install NGINX from source with specified configuration
cd nginx-1.24.0
./configure --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-lUTckl/nginx-1.18.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
            --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' \
            --with-ld-opt=-Wl,-export-dynamic \
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --conf-path=/etc/nginx/nginx.conf \
            --http-log-path=/var/log/nginx/access.log \
            --error-log-path=/var/log/nginx/error.log \
            --lock-path=/var/lock/nginx.lock \
            --pid-path=/run/nginx.pid \
            --modules-path=/usr/lib/nginx/modules \
            --http-client-body-temp-path=/var/lib/nginx/body \
            --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
            --http-proxy-temp-path=/var/lib/nginx/proxy \
            --http-scgi-temp-path=/var/lib/nginx/scgi \
            --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
            --with-debug \
            --with-compat \
            --with-pcre-jit \
            --with-http_ssl_module \
            --with-http_stub_status_module \
            --with-http_realip_module \
            --with-http_auth_request_module \
            --with-http_v2_module \
            --with-http_dav_module \
            --with-http_slice_module \
            --with-threads \
            --with-http_addition_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_image_filter_module=dynamic \
            --with-http_sub_module \
            --with-http_xslt_module=dynamic \
            --with-stream \
            --with-stream_ssl_module \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --add-module=../headers-more-nginx-module \
            --add-module=../nginx-module-vts

make -j 12
make install
