docker kill $(docker ps -q) | true
rm -rf /opt/worker
docker ps
