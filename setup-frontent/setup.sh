#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PLAYBOOK="${SCRIPT_DIR}/setup-frontend.yml"

if [[ ! -f "${REPO_ROOT}/frontend/main/package.json" ]]; then
  echo "Error: expected frontend/main/package.json under ${REPO_ROOT}" >&2
  echo "Clone git@github.com:f5selevin/arcadia2.0.git and run this script from that clone." >&2
  exit 1
fi

if [[ ! -f /etc/os-release ]] || ! grep -q '^ID="\?amzn"\?$' /etc/os-release; then
  echo "Error: this installer supports Amazon Linux only." >&2
  exit 1
fi

run_as_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Installing Ansible..."
  if ! run_as_root dnf install -y ansible-core; then
    run_as_root dnf install -y python3 python3-pip
    python3 -m pip install --user ansible-core
    export PATH="${HOME}/.local/bin:${PATH}"
  fi
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Error: ansible-playbook was not installed successfully." >&2
  exit 1
fi

echo "Configuring the Arcadia frontend from ${REPO_ROOT}..."
ansible-playbook \
  --inventory 'localhost,' \
  --connection local \
  --extra-vars "repo_root=${REPO_ROOT}" \
  "${PLAYBOOK}"

echo "Frontend setup complete. Test it with: curl -i http://127.0.0.1/healthz"
