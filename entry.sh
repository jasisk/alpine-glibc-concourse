#!/bin/sh

ROOT_DIR=${PWD}

: ${KEYS_DIR:="${ROOT_DIR}/keys/"}
: ${SESSION_SIGNING_KEY_NAME:='session_signing_key'}
: ${TSA_HOST_KEY_NAME:='tsa_host_key'}
: ${WORKER_KEY_NAME:='worker_key'}
: ${AUTHORIZED_WORKER_KEYS_NAME:='authorized_worker_keys'}

gen_key() (
  mkdir -p "${KEYS_DIR}"
  cd "${KEYS_DIR}"

  for k; do
    [ -f "${KEYS_DIR}/$k" ] && continue

    echo "Generating $k ..."
    ssh-keygen -q -t rsa -f $k -N ''
  done
)

key_path() {
  echo "${KEYS_DIR}/$*"
}

if [ "$1" = 'concourse' ]; then
  chown -R concourse:concourse /opt/concourse
  case "$2" in
    worker)
      exec /usr/bin/env "$@" ;;
    *)
      exec su-exec concourse:concourse /usr/bin/env "$@"
  esac
fi

case "$1" in
  web)
    gen_key ${SESSION_SIGNING_KEY_NAME} ${TSA_HOST_KEY_NAME} ${WORKER_KEY_NAME}

    cat < "${KEYS_DIR}/${WORKER_KEY_NAME}.pub" >> \
      "${KEYS_DIR}/${AUTHORIZED_WORKER_KEYS_NAME}"

    : ${CONCOURSE_TSA_HOST_KEY:="$(key_path ${TSA_HOST_KEY_NAME})"}
    : ${CONCOURSE_TSA_AUTHORIZED_KEYS:="$(key_path ${AUTHORIZED_WORKER_KEYS_NAME})"}
    : ${CONCOURSE_SESSION_SIGNING_KEY:="$(key_path ${SESSION_SIGNING_KEY_NAME})"}

    export CONCOURSE_TSA_HOST_KEY CONCOURSE_TSA_AUTHORIZED_KEYS CONCOURSE_SESSION_SIGNING_KEY
    ;;
  worker)
    gen_key ${WORKER_KEY_NAME}
    : ${CONCOURSE_TSA_PUBLIC_KEY:="keys/${TSA_HOST_KEY_NAME}.pub"}
    [ -f "${CONCOURSE_TSA_PUBLIC_KEY}" ] || {
      echo "FATAL: expected ${CONCOURSE_TSA_PUBLIC_KEY} to exist."
      exit 1
    }
    mkdir -p "${CONCOURSE_WORK_DIR:="${ROOT_DIR}/work"}"
    : ${CONCOURSE_TSA_WORKER_PRIVATE_KEY:="$(key_path ${WORKER_KEY_NAME})"}
    export CONCOURSE_TSA_WORKER_PUBLIC_KEY CONCOURSE_WORK_DIR
    ;;
  *)
    exec "$@"
esac

exec "$0" concourse "$@"
