#!/bin/bash

# WORKDIR $CATALINA_HOME

if [ -z "$LETSENCRYPT_CERT_DIR" ] ; then
    echo '$LETSENCRYPT_CERT_DIR not set'
    exit 1
fi

if [ -z "$PKCS12_PASSWORD" ] ; then
    echo '$PKCS12_PASSWORD not set'
    exit 1
fi

if [ -z "$JKS_KEY_PASSWORD" ] ; then
    echo '$JKS_KEY_PASSWORD not set'
    exit 1
fi

if [ -z "$JKS_STORE_PASSWORD" ] ; then
    echo '$JKS_STORE_PASSWORD not set'
    exit 1
fi

# convert LetsEncrypt certificates
# https://community.letsencrypt.org/t/cry-for-help-windows-tomcat-ssl-lets-encrypt/22902/4

# remove existing keystores

rm -f $P12_FILE
rm -f $JKS_FILE

# convert PEM to PKCS12

openssl pkcs12 -export \
  -in $LETSENCRYPT_CERT_DIR/fullchain.pem \
  -inkey $LETSENCRYPT_CERT_DIR/privkey.pem \
  -name $KEY_ALIAS \
  -out $P12_FILE \
  -password pass:$PKCS12_PASSWORD

# import PKCS12 into JKS

keytool -importkeystore \
  -alias $KEY_ALIAS \
  -destkeypass $JKS_KEY_PASSWORD \
  -destkeystore $JKS_FILE \
  -deststorepass $JKS_STORE_PASSWORD \
  -srckeystore $P12_FILE \
  -srcstorepass $PKCS12_PASSWORD \
  -srcstoretype PKCS12

# change server configuration

HTTP_PROXY_NAME_PARAM="--stringparam http.proxyName $HTTP_PROXY_NAME "
HTTP_PROXY_PORT_PARAM="--stringparam http.proxyPort $HTTP_PROXY_PORT "
HTTP_REDIRECT_PORT_PARAM="--stringparam http.redirectPort $HTTP_REDIRECT_PORT "
HTTPS_PORT_PARAM="--stringparam https.port $HTTPS_PORT "
HTTPS_MAX_THREADS_PARAM="--stringparam https.maxThreads $HTTPS_MAX_THREADS "
HTTPS_CLIENT_AUTH_PARAM="--stringparam https.clientAuth $HTTPS_CLIENT_AUTH "
HTTPS_PROXY_NAME_PARAM="--stringparam https.proxyName $HTTPS_PROXY_NAME "
HTTPS_PROXY_PORT_PARAM="--stringparam https.proxyPort $HTTPS_PROXY_PORT "
JKS_FILE_PARAM="--stringparam https.keystoreFile $JKS_FILE "
JKS_KEY_PASSWORD_PARAM="--stringparam https.keystorePass $JKS_KEY_PASSWORD "
KEY_ALIAS_PARAM="--stringparam https.keyAlias $KEY_ALIAS "
JKS_STORE_PASSWORD_PARAM="--stringparam https.keyPass $JKS_STORE_PASSWORD "

transform="xsltproc \
  --output conf/server.xml \
  $HTTP_PROXY_NAME_PARAM \
  $HTTP_PROXY_PORT_PARAM \
  $HTTP_REDIRECT_PORT_PARAM \
  $HTTPS_PORT_PARAM \
  $HTTPS_MAX_THREADS_PARAM \
  $HTTPS_CLIENT_AUTH_PARAM \
  $HTTPS_PROXY_NAME_PARAM \
  $HTTPS_PROXY_PORT_PARAM \
  $JKS_FILE_PARAM \
  $JKS_KEY_PASSWORD_PARAM \
  $KEY_ALIAS_PARAM \
  $JKS_STORE_PASSWORD_PARAM \
  conf/letsencrypt-tomcat.xsl \
  conf/server.xml"

echo $transform

eval $transform

# run Tomcat

catalina.sh run