FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

ARG FRAPPE_USER=frappe
ARG ADMIN_PASSWORD=admin123
ARG SITE_NAME=erp.gumite.com

# 1) System deps (no in-container MariaDB server)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget git curl \
        python3-minimal python3-pip python3-distutils \
        build-essential \
        libmariadb-dev-compat libmariadb-dev mariadb-client \
        redis-server \
    && rm -rf /var/lib/apt/lists/*

# 2) Ensure pip can see click 8.2.0
RUN pip3 install --upgrade pip setuptools wheel

# 3) Bench CLI + click
RUN pip3 install frappe-bench click~=8.2.0

# 4) Create frappe user
RUN useradd --create-home --shell /bin/bash $FRAPPE_USER \
    && mkdir -p /home/$FRAPPE_USER/frappe-bench \
    && chown -R $FRAPPE_USER:$FRAPPE_USER /home/$FRAPPE_USER

USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER

# 5) Init bench, create site, install ERPNext
RUN bench init --frappe-branch version-14 frappe-bench \
    && cd frappe-bench \
    && bench new-site $SITE_NAME \
         --db-type mariadb \
         --db-host $MYSQLHOST \
         --db-port $MYSQLPORT \
         --db-root-username $MYSQLUSER \
         --db-root-password $MYSQLPASSWORD \
         --db-name $MYSQLDATABASE \
         --admin-password $ADMIN_PASSWORD \
    && bench get-app erpnext https://github.com/frappe/erpnext --branch version-14 \
    && bench --site $SITE_NAME install-app erpnext

EXPOSE 8000
CMD ["bash", "-lc", "cd frappe-bench && bench start --production"]
