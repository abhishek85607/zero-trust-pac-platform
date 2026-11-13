# Zero-Trust Cloud & Policy-as-Code Platform

An end-to-end DevSecOps & Cloud Security implementation enforcing Zero-Trust guardrails across Kubernetes workloads, dynamic secrets management, and Infrastructure-as-Code (IaC).

## Architecture Overview
[ Developer / CI/CD Push ]
│
▼
[ Kyverno Admission Controller ]  ──► Blocks Root, Privileged & Unbounded Pods
│ (Compliant)
▼
[ HashiCorp Vault Sidecar ]       ──► Dynamic Secrets via K8s ServiceAccount Auth
│
▼
[ Terraform + LocalStack Cloud ]  ──► KMS-Encrypted S3 & Least-Privilege IAM


## Implemented Modules

1. **Policy-as-Code Admission Control (`kyverno-policies/`)**
   - `disallow-root-user.yaml`: Enforces `runAsNonRoot: true`.
   - `disallow-privileged.yaml`: Blocks privileged container escalation.
   - `require-resource-limits.yaml`: Mandates CPU and memory limits on all pods.
   - Verified via `test-manifests/` (`insecure-pod.yaml` rejected; `compliant-pod.yaml` admitted).

2. **Dynamic Secrets Management (`vault-setup/`)**
   - HashiCorp Vault deployed with Kubernetes Auth method bound to `vault-app-sa`.
   - Sidecar agent injector mounts runtime credentials at `/vault/secrets/db-config.txt` with zero hardcoded Kubernetes secrets.

3. **Zero-Trust Cloud Infrastructure (`terraform-localstack/`)**
   - Automated AWS cloud provisioning via Terraform against LocalStack (`S3`, `KMS`, `IAM`).
   - Enforces KMS key rotation, server-side KMS encryption on S3, S3 Public Access Block, and least-privilege read-only IAM policies.
