# ───────────────────────────────────────────────────────────────────────────────
# Single‐container ERPNext v14 for Railway (production mode)
# ───────────────────────────────────────────────────────────────────────────────

FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Override these via Railway “Variables” if desired
ARG FRAPPE_USER=frappe
ARG ADMIN_PASSWORD=admin123
ARG SITE_NAME=erp.gumite.com

# 1) Install system dependencies (no in-container DB server)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       wget git curl \
       python3-minimal python3-pip python3-distutils \
       build-essential \
       libmariadb-dev-compat libmariadb-dev mariadb-client \
       redis-server \
  && rm -rf /var/lib/apt/lists/*

# 2) Upgrade pip so it can resolve needed dependencies
RUN pip3 install --upgrade pip setuptools wheel

# 3) Install Bench CLI (pin to last release compatible with Click 8.1.8)
RUN pip3 install frappe-bench==5.24.0

# 4) Create frappe system user and working directory
RUN useradd --create-home --shell /bin/bash $FRAPPE_USER \
  && mkdir -p /home/$FRAPPE_USER/frappe-bench \
  && chown -R $FRAPPE_USER:$FRAPPE_USER /home/$FRAPPE_USER

USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER

# 5) Initialize bench, create site & install ERPNext v14
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
  && bench get-app erpnex
