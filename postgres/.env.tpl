PATRONI_SUPERUSER_PASSWORD={{ getSecret "superuser_password" }}
PATRONI_REPLICATION_PASSWORD={{ getSecret "replication_password" }}
PATRONI_RESTAPI_USERNAME=patroni
PATRONI_RESTAPI_PASSWORD={{ getSecret "restapi_password" }}
