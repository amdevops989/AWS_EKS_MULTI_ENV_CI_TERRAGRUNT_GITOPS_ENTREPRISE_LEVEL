# 1. The Identity Governance Matrix ( AWS )

[Identity Directory]            [IAM Identity Center Groups]             [Target AWS Accounts & Permission Sets]

   ┌── devops ──┐                                                         ┌──> IronCore (Prod) ───────> AWSAdministratorAccess
   │            ├─── (Member of) ───>  DevOps-Team  ─── (Assigned to) ────┤
   └── ...    ──┘                                                         └──> IronCoreSandboxDev ───> AWSAdministratorAccess


   ┌── developer ┐                                                        ┌──> IronCore (Prod) ───────> AWSReadOnlyAccess
   │             ├─── (Member of) ───> Developer-Team ─── (Assigned to) ──┤
   └── ...     ──┘                                                        └──> IronCoreSandboxDev ───> AWSAdministratorAccess

## 2 Setting up the AWs Cli Profiles

aws configure sso


Because we operate in a multi-account AWS Organization environment, order of operations is critical. I use Terragrunt to provision the foundational layer—VPC, RDS, EKS, and IAM roles. Inside Kubernetes, I always deploy Cert-Manager first because admission controllers like Kyverno need TLS certificates to function. Next, I bring up Vault and External Secrets Operator so secrets are available before ArgoCD starts syncing applications. Once the security, mesh, and observability layers are healthy, ArgoCD manages the application lifecycle and progressive Canary rollouts

## infra Deploy order for Eks and addons

┌────────────────────────────────────────────────────────────────────────┐
│                        LAYER 1: CLUSTER CORE                           │
│  EKS Cluster + IRSA (IAM Roles) + EBS CSI Driver + AWS KMS + S3         │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│                       LAYER 2: AUTOSCALING & MESH                      │
│  1. Karpenter (Node Autoscaler)                                        │
│  2. Cert-Manager & ExternalDNS (TLS Certificates & Route53 Sync)       │
│  3. Istio Service Mesh (Control Plane + Ingress Gateways)              │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│                      LAYER 3: SECURITY & IDENTITY                      │
│  4. HashiCorp Vault (App Secrets, PKI, Auto-unseal via KMS)           │
│  5. Kyverno (Admission Control & EKS Policy Guardrails)                │
│  6. Falco (Kernel eBPF System-Call Security)                           │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│                    LAYER 4: OBSERVABILITY & SIEM                       │
│  7. kube-prometheus-stack (Prometheus, Grafana, Alertmanager)          │
│  8. ELK Stack + Wazuh (Log Aggregation & Integrated SIEM)              │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│                   LAYER 5: WORKLOADS & BACKUPS                         │
│  9. Microservices App (Deployed into Istio Mesh with Vault Injection)  │
│ 10. Kasten K10 (Stateful Backups & S3 Snapshot Exports)                │
└────────────────────────────────────────────────────────────────────────┘

Step-by-Step Execution Rationale
Phase 1: Cluster Core & Karpenter
EKS Core & Storage drivers: Provision the control plane, KMS keys, S3 buckets, and the EBS CSI Driver first so PVCs can bind.

Karpenter: Deploys right after the control plane. Having Karpenter active ensures that as soon as memory-heavy pods (like Elasticsearch or Prometheus) hit the API, Karpenter automatically provisions the exact EC2 instances (t3.xlarge, c6i.xlarge, etc.) needed.

Phase 2: Ingress & Mesh Foundation
Cert-Manager & ExternalDNS: Handles Let's Encrypt certificates and dynamic Route53 DNS records.

Istio: Deploys istiod and istio-ingress. Works directly with Cert-Manager and ExternalDNS to expose cluster services over HTTPS safely.

Phase 3: Security Gates & Runtime Enforcement
HashiCorp Vault: Establishes secret injection capabilities and internal PKI.

Kyverno: Active before microservices and observability tools launch, enforcing policies (e.g., forcing sidecar injection, verifying signed images, requiring non-root execution).

Falco: eBPF drivers start inspecting system calls across all current and future worker nodes.

Phase 4: Observability & SIEM
kube-prometheus-stack: Monitors cluster metrics, Karpenter node scaling, Istio service mesh health, and custom app metrics.

ELK Stack + Wazuh: Ingests EKS audit logs, pod logs via Filebeat, and Falco events via falcosidekick into unified SIEM dashboards.

Phase 5: Workloads & Disaster Recovery
Microservices Application: Deployed into the Istio mesh with Kyverno policies validated, Prometheus annotations attached, and Vault agent secrets injected.

Kasten K10: Runs last to discover all deployed stateful workloads, Istio configs, and secrets across namespaces, backing them up via EBS snapshots and encrypted S3 exports.