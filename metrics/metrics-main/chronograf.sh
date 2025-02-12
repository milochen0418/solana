#!/bin/bash -ex
#
# (Re)starts the Chronograf containers
#

cd "$(dirname "$0")"

if [[ -z $HOST ]]; then
  HOST=metrics.solana.com
fi
echo "HOST: $HOST"

: "${CHRONOGRAF_IMAGE:=chronograf:1.9.4}"

# remove the container
container=chronograf
[[ -w /var/lib/$container ]]
[[ -x /var/lib/$container ]]

(
  set +e
  sudo docker kill $container
  sudo docker rm -f $container
  exit 0
)

pwd
rm -rf certs
mkdir -p certs
chmod 700 certs
sudo cp /etc/letsencrypt/live/"$HOST"/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/"$HOST"/privkey.pem certs/
sudo chmod 0444 certs/*
sudo chown buildkite-agent:buildkite-agent certs



#(Re) start the container
sudo docker run \
  --detach \
  --env AUTH_DURATION=24h \
  --env inactivity-duration=48h \
  --env GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID_8888" \
  --env GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET_8888" \
  --env PUBLIC_URL=https://metrics.solana.com:8888 \
  --env GOOGLE_DOMAINS=solana.com,jito.wtf,jumpcrypto.com,certus.one,mango.markets,influxdata.com,solana.org  \
  --env TLS_CERTIFICATE=/certs/fullchain.pem \
  --env TLS_PRIVATE_KEY=/certs/privkey.pem \
  --env TOKEN_SECRET="$TOKEN_SECRET" \
  --name=chronograf \
  --net=influxdb \
  --publish 8888:8888 \
  --user 0:0 \
  --volume "$PWD"/certs:/certs \
  --volume /var/lib/chronograf:/var/lib/chronograf \
  --log-opt max-size=1g \
  --log-opt max-file=5 \
  $CHRONOGRAF_IMAGE --influxdb-url=https://metrics.solana.com:8086 --auth-duration="720h" --inactivity-duration="48h"
