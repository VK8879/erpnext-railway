# ───────────────────────────────────────────────────────────────────────────────
# Single‐container ERPNext v14 for Railway (production mode)
# ───────────────────────────────────────────────────────────────────────────────

FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Override these via Railway Variables if you like
ARG FRAPPE_USER=frappe
ARG ADMIN_PASSWORD=admin123
ARG SITE_NAME=erp.gumite.com

# 1) System deps (no in-container DB server)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       wget git curl \
       python3-minimal python3-pip python3-distutils \
       build-essential \
       libmariadb-dev-compat libmariadb-dev mariadb-client \
       redis-server \
  && rm -rf /var/lib/apt/lists/*

# 2) Upgrade pip so it sees all modern packages
RUN pip3 install --upgrade pip setuptools wheel

# 3) Install Bench CLI (compatible with Click 8.1.8)
RUN pip3 install frappe-bench==5.24.1

# 4) Create frappe user & home
RUN useradd --create-home --shell /bin/bash $FRAPPE_USER \
  && mkdir -p /home/$FRAPPE_USER/frappe-bench \
  && chown -R $FRAPPE_USER:$FRAPPE_USER /home/$FRAPPE_USER

USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER

# 5) Initialize bench (only once) 
RUN bench init --frappe-branch version-14 frappe-bench

# 6) Switch into the bench folder to create the site and install ERPNext
WORKDIR /home/$FRAPPE_USER/frappe-bench

RUN bench new-site $SITE_NAME \
