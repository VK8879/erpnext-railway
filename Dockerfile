FROM frappe/erpnext-worker:v14

ENV SITE_NAME=erp.gumite.com
ENV DB_ROOT_PASSWORD=admin
ENV ADMIN_PASSWORD=admin123
ENV INSTALL_APPS=erpnext

RUN bench new-site $SITE_NAME \
  --admin-password $ADMIN_PASSWORD \
  --mariadb-root-password $DB_ROOT_PASSWORD \
  && bench get-app erpnext --branch version-14 \
  && bench --site $SITE_NAME install-app erpnext

CMD ["bench", "start"]
