# ───────────────────────────────────────────────────────────────────────────────
# Single‐container ERPNext v14 for Railway (production mode)
# ───────────────────────────────────────────────────────────────────────────────

# 1. Base on Ubuntu 20.04
FROM ubuntu:20.04

# 2. Avoid interactive prompts during apt operations
ENV DEBIAN_FRONTEND=noninteractive

# 3. Build‐time args (you can override via Railway “Variables”)
ARG FRAPPE_USER=frappe
ARG DB_ROOT_PASSWORD=admin
ARG ADMIN_PASSWORD=admin123
ARG SITE_NAME=erp.gumite.com

# 4. Install system dependencies, MariaDB, Redis, Supervisor, Git, Python 3
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        git \
        curl \
        python3-minimal \
        python3-pip \
        python3-distutils \
        build-essential \
        libmariadb-dev-compat \
        libmariadb-dev \
        mariadb-server \
        redis-server \
        supervisor \
    && pip3 install frappe-bench \
    && rm -rf /var/lib/apt/lists/*

# 5. Create the `frappe` user and home directory
RUN useradd --create-home --shell /bin/bash $FRAPPE_USER \
    && mkdir -p /home/$FRAPPE_USER/frappe-bench \
    && chown -R $FRAPPE_USER:$FRAPPE_USER /home/$FRAPPE_USER

# 6. Switch to the frappe user for bench operations
USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER

# 7. Download the latest install.py from the develop branch,
#    patch bench to use lukptr/bench-docker (for Docker compatibility),
#    then run the production install.
RUN wget https://raw.githubusercontent.com/frappe/bench/develop/install.py \
    && sed -i -e 's,frappe/bench,lukptr/bench-docker,' install.py \
    && python3 install.py --production --user $FRAPPE_USER \
         --mysql-root-password $DB_ROOT_PASSWORD \
         --admin-password $ADMIN_PASSWORD \
    && rm -f install.py

# 8. Create a new site, fetch ERPNext v14, and install the “erpnext” app
RUN source /home/$FRAPPE_USER/.bashrc \
    && bench new-site $SITE_NAME \
         --admin-password $ADMIN_PASSWORD \
         --mariadb-root-password $DB_ROOT_PASSWORD \
    && bench get-app erpnext --branch version-14 \
    && bench --site $SITE_NAME install-app erpnext

# 9. (Optional) Set up production supervisor configs for ERPNext:
#    This will generate the standard nginx + supervisor configs under
#    /etc/supervisor/conf.d/ and /etc/nginx/sites-available/
#    If you don’t need nginx (e.g., you’re proxying through Railway),
#    you can skip `bench setup production` and just run `bench start`.
RUN bench setup production $FRAPPE_USER

# 10. Expose port 8000 (ERPNext’s default)
EXPOSE 8000

# 11. Start ERPNext
CMD ["bench", "start"]
