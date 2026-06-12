kubeseal --fetch-cert \
  --controller-namespace=kube-system \
  --controller-name=sealed-secrets \
  --controller-port=8080 > pub-cert.pem



kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  --controller-port=8086 \
  --format=yaml < app-secrets.yaml > app-sealedsecret.yaml

## ofline

curl http://localhost:8080/v1/cert.pem -o pub-cert.pem

kubeseal --cert pub-cert.pem --format=yaml < app-secrets.yaml > app-sealedsecret.yaml


## ci :
#!/bin/bash
set -euo pipefail

# -----------------------------
# Config
# -----------------------------
SECRET_FILE="/gitops/cluster/infra/dev/app-secrets.yaml"  # input Secret YAML
SEALED_FILE="/gitops/cluster/infra/dev/app-sealedsecret.yaml"  # output SealedSecret YAML
NAMESPACE="default"          # target namespace for your secret
SEALED_NAMESPACE="kube-system"     # SealedSecrets controller namespace
CONTROLLER_NAME="sealed-secrets"

# -----------------------------
# Step 1: Port-forward SealedSecrets controller
# -----------------------------
echo "[INFO] Starting port-forward to SealedSecrets controller..."
kubectl -n ${SEALED_NAMESPACE} port-forward svc/${CONTROLLER_NAME} 8080:8080 >/dev/null 2>&1 &
PF_PID=$!
sleep 3  # wait for port-forward to start

# -----------------------------
# Step 2: Fetch public cert
# -----------------------------
echo "[INFO] Fetching SealedSecrets public certificate..."
curl -s http://localhost:8080/v1/cert.pem -o /tmp/pub-cert.pem

# -----------------------------
# Step 3: Seal the secret
# -----------------------------
echo "[INFO] Encrypting secret into SealedSecret..."
kubeseal --cert /tmp/pub-cert.pem --format=yaml \
  --namespace ${NAMESPACE} < "${SECRET_FILE}" > "${SEALED_FILE}"

echo "[INFO] SealedSecret created at ${SEALED_FILE}"

# -----------------------------
# Step 4: Cleanup
# -----------------------------
echo "[INFO] Cleaning up..."
kill $PF_PID
rm -f /tmp/pub-cert.pem

echo "[INFO] Done!"
