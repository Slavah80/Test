# Secure mTLS Certificate Distribution and Secrets Management on AWS - Reference Architecture

> **Classification**: Reference Architecture
> **Last Updated**: 2025-01-11
> **Applies to**: AWS Certificate Manager (ACM), AWS Secrets Manager, AWS KMS, .NET 6.0+
> **Compliance**: SOC 2 Type II

## Overview

This reference architecture demonstrates how to build a SOC 2-compliant secrets management and certificate distribution system using AWS managed services. The architecture enables secure mutual TLS (mTLS) authentication between distributed applications and services while providing centralized secrets management with automatic rotation capabilities. Sensitive data is encrypted at rest using AWS KMS and securely delivered to client applications through a C# agent that integrates with the Windows Credential Manager for last-mile secret storage.

The architecture leverages AWS Certificate Manager Private Certificate Authority (ACM Private CA) to issue and manage X.509 certificates for mTLS, AWS Secrets Manager for centralized secret storage with automatic rotation, and AWS KMS for envelope encryption of sensitive data. The C# agent acts as a secure bridge between AWS services and client applications, retrieving certificates and secrets over encrypted channels and storing them in the operating system's native credential store.

This baseline architecture is suitable for enterprises requiring zero-trust network security, certificate-based authentication, and centralized secrets management with comprehensive audit trails. The design follows Azure Well-Architected Framework principles to ensure reliability, security, cost optimization, operational excellence, and performance efficiency across all components.

### Key capabilities

- **Zero-trust mTLS authentication**: Certificate-based mutual authentication eliminates reliance on network perimeter security and enables identity verification at the transport layer
- **Automated certificate lifecycle management**: ACM Private CA handles certificate issuance, renewal, and revocation with configurable validity periods and automated rotation policies
- **Centralized secrets management with rotation**: AWS Secrets Manager stores sensitive data encrypted at rest, supports automatic rotation with AWS Lambda, and maintains version history for rollback capabilities
- **Envelope encryption for data protection**: AWS KMS provides hardware-backed cryptographic keys with automatic rotation, envelope encryption for secrets, and fine-grained access control through IAM policies
- **OS-integrated credential storage**: Windows Credential Manager provides encrypted storage for last-mile secrets with user-level or system-level isolation and Windows ACL protection

### Architecture characteristics

| Characteristic | Description |
|----------------|-------------|
| **Workload type** | Security infrastructure, Secrets management, Certificate authority |
| **Scale** | Enterprise (1,000+ distributed agents across multiple AWS regions) |
| **Availability** | 99.9% (AWS managed services with multi-AZ deployment) |
| **Security level** | Private (VPC-based architecture with no public internet exposure for certificate/secret retrieval) |
| **Compliance** | SOC 2 Type II certified (AWS services), FIPS 140-2 Level 3 validated (AWS KMS HSMs) |

## Scenario

### Business context

Organizations managing distributed applications across cloud and hybrid environments face significant challenges in securing service-to-service communication and protecting sensitive credentials. Traditional approaches using shared secrets or network-based security perimeter are insufficient for zero-trust architectures. Applications require strong cryptographic identity through mutual TLS authentication, while development teams need secure access to API keys, database credentials, and third-party service tokens without embedding secrets in code or configuration files.

Compliance frameworks such as SOC 2 mandate strict controls over cryptographic key management, access logging, secret rotation, and separation of duties. Manual certificate management processes are error-prone and create operational overhead. Organizations need automated certificate lifecycle management integrated with centralized secrets storage that provides comprehensive audit trails and supports automated rotation to reduce the risk of credential compromise.

This architecture addresses these requirements by implementing a certificate authority for issuing short-lived mTLS certificates, centralized secrets management with automatic rotation, and envelope encryption using hardware-backed cryptographic keys. The C# agent provides a secure, auditable interface for applications to retrieve certificates and secrets, with last-mile storage in Windows Credential Manager protecting against memory scraping and providing OS-level access controls.

### Use cases

This architecture is suitable for:

1. **Microservices with mTLS authentication**: When service mesh or sidecar proxies require X.509 certificates for mutual authentication between services, ensuring that only authenticated services can communicate. ACM Private CA issues short-lived certificates (1-7 day validity) with automatic renewal to minimize the impact of certificate compromise.

2. **Hybrid cloud applications requiring secrets synchronization**: When on-premises applications or edge devices need secure access to cloud-hosted secrets such as database connection strings, API keys for third-party services, or OAuth tokens. The C# agent retrieves secrets over TLS 1.3 connections and stores them in Windows Credential Manager for local application access.

3. **SOC 2 compliance for cryptographic operations**: When audit requirements mandate comprehensive logging of all key usage, secret access, certificate issuance, and rotation events. AWS CloudTrail captures all API calls, while AWS Config monitors configuration changes and compliance status against security baselines.

4. **Automated credential rotation for databases and APIs**: When security policies require regular rotation of database passwords, API keys, or service account credentials without application downtime. AWS Secrets Manager's Lambda-based rotation functions update credentials in target systems and maintain multiple versions for graceful cutover.

5. **Certificate-based authentication for DevOps tools**: When CI/CD pipelines, monitoring agents, or infrastructure automation tools require strong authentication using client certificates instead of static tokens or passwords. ACM Private CA issues certificates with organizational unit (OU) fields for role-based authorization.

### Not suitable for

This architecture may not be appropriate when:

- **Public-facing TLS certificates are required**: ACM Private CA issues certificates for internal use only. For public-facing web servers requiring browser-trusted certificates, use AWS Certificate Manager (ACM) public certificates instead, which are issued by Amazon's publicly trusted certificate authority and automatically deployed to load balancers and CloudFront distributions.

- **Non-Windows operating systems require credential storage**: This architecture uses Windows Credential Manager for last-mile secret storage. For Linux-based systems, adapt the C# agent to use alternatives such as GNOME Keyring, KWallet, or systemd credentials, or store secrets in file-based secret stores with strict file permissions (0600).

- **Extremely low-latency operations (sub-millisecond)**: AWS Secrets Manager API calls introduce network latency (typically 50-150ms). For applications requiring sub-millisecond secret retrieval, implement local caching with in-memory secrets, monitoring Secrets Manager for version changes using EventBridge notifications to refresh the cache.

- **Air-gapped or fully disconnected environments**: This architecture requires connectivity to AWS API endpoints. For air-gapped environments, implement AWS Outposts with local KMS and Secrets Manager, or use offline certificate distribution through secure media transfer with manual secret deployment.

## Architecture

### Architecture diagram

> **Note**: Visual diagram files are referenced below. For detailed specifications to create these diagrams using Visio, draw.io, or other tools, see `aws-mtls-secrets-architecture-diagrams-spec.md`. An ASCII representation is provided below for immediate reference.

![Architecture diagram](./images/aws-mtls-secrets-architecture.svg)

*Download a [Visio file](./visio/aws-mtls-secrets-architecture.vsdx) of this architecture.*

**ASCII Architecture Representation** (for immediate use):

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                  AWS Secure mTLS Secrets Management Architecture                 │
│                                Region: us-east-1                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐                    ┌──────────────────────────────────────┐
│  Administrator  │──[TLS 1.3+MFA]────>│  AWS IAM Identity Center (SSO)       │
│   (Workstation) │                    │  - Multi-factor authentication       │
└─────────────────┘                    │  - SAML 2.0 federation               │
                                       └──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                             VPC: 10.0.0.0/16                                     │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐      │
│  │                   Application Load Balancer                           │      │
│  │                 HTTPS Listener (Port 443)                             │      │
│  │            Health Check: /health (30s interval)                       │      │
│  └────────┬────────────────────┬───────────────────────┬─────────────────┘     │
│           │                    │                       │                       │
│  ┌────────▼──────────┐  ┌──────▼─────────┐  ┌─────────▼────────┐            │
│  │ AZ 1: us-east-1a  │  │ AZ 2: us-east-1b│  │ AZ 3: us-east-1c │            │
│  │                   │  │                 │  │                  │            │
│  │ ┌───────────────┐│  │ ┌─────────────┐│  │ ┌──────────────┐│            │
│  │ │ EC2: Agent    ││  │ │ EC2: Agent  ││  │ │ EC2: Agent   ││            │
│  │ │ t3.micro      ││  │ │ t3.micro    ││  │ │ t3.micro     ││            │
│  │ │ Win Server 19 ││  │ │ Win Server  ││  │ │ Win Server   ││            │
│  │ │ 10.0.1.10     ││  │ │ 10.0.2.10   ││  │ │ 10.0.3.10    ││            │
│  │ └───────┬───────┘│  │ └─────┬───────┘│  │ └──────┬───────┘│            │
│  └─────────┼─────────┘  └───────┼─────────┘  └────────┼─────────┘            │
│            │ [HTTPS/443]        │ [HTTPS/443]         │ [HTTPS/443]          │
│            │                    │                     │                       │
│  ┌─────────▼────────────────────▼─────────────────────▼────────────────┐     │
│  │              VPC Interface Endpoints (PrivateLink)                   │     │
│  │  ┌───────────────┐  ┌────────────────┐  ┌──────────────────┐      │     │
│  │  │ ACM Private CA│  │ Secrets Manager│  │ AWS KMS          │      │     │
│  │  │ 10.0.11.10    │  │ 10.0.11.20     │  │ 10.0.11.30       │      │     │
│  │  └───────┬───────┘  └────────┬───────┘  └──────────┬───────┘      │     │
│  └──────────┼──────────────────┼──────────────────────┼──────────────┘     │
│             │ [PrivateLink]    │ [PrivateLink]        │ [PrivateLink]      │
└─────────────┼──────────────────┼──────────────────────┼────────────────────┘
              │                  │                      │
  ┌───────────▼────────┐  ┌──────▼──────────┐  ┌───────▼────────────┐
  │ ACM Private CA     │  │ AWS Secrets     │  │ AWS KMS            │
  │ Service (Managed)  │  │ Manager         │  │ Service (Managed)  │
  │ - Issue certs      │  │ - Store secrets │  │ - Encrypt/Decrypt  │
  │ - 7-day validity   │  │ - Auto rotation │  │ - FIPS 140-2 L3    │
  └────────────────────┘  └─────────────────┘  └────────────────────┘
              │                     │                     │
              └─────────────────────┴─────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ↓                               ↓
        ┌────────────────────┐         ┌─────────────────────┐
        │ Amazon CloudWatch  │         │ AWS CloudTrail      │
        │ - Dashboards       │         │ - Audit logs        │
        │ - Alarms           │         │ - S3: 7yr retention │
        └────────────────────┘         └─────────────────────┘

┌────────────────────────────────────────────────────────────────────────────┐
│               Windows Agent Host (Local Storage)                            │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐│
│  │ C# Secrets Management Agent (Windows Service)                         ││
│  │ - Certificate retrieval & caching (12h TTL)                           ││
│  │ - Secret synchronization (5min TTL)                                   ││
│  └─────────────────────────┬─────────────────────────────────────────────┘│
│                            │ [CredWrite API]                              │
│                            ↓                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │ Windows Credential Manager (OS Component)                           │ │
│  │ - Encryption: Windows DPAPI (AES-256)                               │ │
│  │ - Access Control: Windows ACLs                                      │ │
│  └─────────────────────────┬───────────────────────────────────────────┘ │
│                            │ [CredRead API]                              │
│                            ↓                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │ Client Application                                                  │ │
│  │ - Retrieves secrets using Windows integrated authentication         │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘

Data Flow: 1) Agent→ACM PCA (IssueCertificate) 2) Agent→Secrets Manager
          (GetSecretValue) 3) Secrets Manager→KMS (Decrypt) 4) Agent→Windows
          Credential Manager 5) Application→Credential Manager 6) All API→CloudTrail
```

### Dataflow

The data flows through the solution as follows:

1. **Administrator provisions ACM Private CA**: Administrator creates Private Certificate Authority in AWS Certificate Manager using AWS CloudFormation or Terraform. The root CA certificate is generated within AWS KMS hardware security modules (HSMs) with a 10-year validity period. The CA is configured with certificate templates defining certificate extensions (key usage, extended key usage, subject alternative names) and validity periods (1-365 days).

2. **C# agent requests certificate**: The C# agent running on Windows server authenticates to AWS using IAM role credentials provided by EC2 instance metadata service (for EC2 instances) or AWS Systems Manager Session Manager (for on-premises servers). The agent calls ACM Private CA `IssueCertificate` API with a certificate signing request (CSR) containing the server's identity information (common name, organizational unit, DNS names).

3. **ACM Private CA issues certificate**: ACM Private CA validates the CSR against certificate templates and IAM policies restricting certificate issuance to authorized principals. The CA signs the certificate using the private key stored in AWS KMS, returning an X.509 certificate chain (leaf certificate + intermediate CA certificate + root CA certificate) to the agent. The certificate is registered in AWS Certificate Manager with automatic renewal notification 30 days before expiration.

4. **Agent retrieves secrets from Secrets Manager**: The C# agent calls AWS Secrets Manager `GetSecretValue` API to retrieve application secrets (database passwords, API keys, OAuth tokens). Secrets Manager returns the secret encrypted with AWS KMS customer master key (CMK). The encrypted secret transits over TLS 1.3 connection, and AWS KMS decrypts the data encryption key (DEK) using envelope encryption before returning plaintext secrets to the agent.

5. **KMS decrypts secret using envelope encryption**: AWS Secrets Manager uses envelope encryption where each secret is encrypted with a unique data encryption key (DEK), and the DEK is encrypted with the KMS customer master key. When the agent requests a secret, Secrets Manager calls KMS `Decrypt` API to decrypt the DEK using the CMK stored in FIPS 140-2 Level 3 validated HSMs. KMS logs the decryption operation to CloudTrail with caller identity, timestamp, and encryption context.

6. **Agent stores secrets in Windows Credential Manager**: The C# agent uses Windows Credential Manager APIs (`CredWrite`, `CredRead`) to store decrypted secrets in the Windows vault. Secrets are stored with `CRED_TYPE_GENERIC` type and protected by Windows Data Protection API (DPAPI), which encrypts credentials using keys derived from the user's logon password or system master key. Credential access is restricted by Windows ACLs to the service account running the agent.

7. **Application retrieves secrets from Credential Manager**: Local applications access secrets through Windows Credential Manager APIs or the C# agent's local API endpoint (optional). Applications authenticate using Windows integrated authentication, and the agent validates the caller's identity against an access control list before returning secrets. The agent logs all secret access attempts to AWS CloudWatch Logs for audit purposes.

8. **Automated secret rotation**: AWS Lambda functions triggered by AWS Secrets Manager rotation schedule connect to target systems (databases, APIs) and update credentials using service-specific APIs. The Lambda function creates a new secret version in Secrets Manager, updates the target system password/token, validates the new credentials work, and marks the version as `AWSCURRENT`. The C# agent polls Secrets Manager for version changes (every 5 minutes) and updates Windows Credential Manager when new versions are available.

### Network architecture

> **Note**: For detailed network diagram specifications including security groups, NACLs, and traffic flows, see `aws-mtls-secrets-architecture-diagrams-spec.md`.

![Network diagram](./images/aws-mtls-secrets-network.svg)

#### Inbound traffic flow

1. **Administrator access to AWS Console/APIs**: Administrators access AWS Management Console through AWS VPN Client or AWS Direct Connect with multi-factor authentication enforced through AWS IAM Identity Center (successor to AWS SSO). All administrative actions are logged to CloudTrail with read/write events captured.

2. **Agent API access to AWS services**: C# agents running on EC2 instances or on-premises servers access AWS APIs (ACM Private CA, Secrets Manager, KMS) through VPC endpoints for AWS PrivateLink. API calls transit private IP space without traversing the public internet. IAM role session policies restrict API access to specific resources based on tags and conditions.

#### Outbound traffic flow

1. **CloudTrail log delivery**: AWS CloudTrail delivers API audit logs to S3 bucket with SSE-KMS encryption using dedicated KMS key. Logs are retained for 7 years to meet SOC 2 compliance requirements. S3 bucket has MFA delete enabled and versioning configured to prevent log tampering.

2. **CloudWatch Logs aggregation**: C# agent application logs and AWS service logs (Lambda execution logs, KMS audit logs) flow to CloudWatch Logs log groups. Logs are encrypted at rest using KMS and retained for 90 days. CloudWatch Logs Insights enables querying and analysis of security events.

3. **EventBridge notifications**: AWS EventBridge captures events from Secrets Manager (secret rotation, secret access), ACM (certificate expiration, certificate renewal), and KMS (key rotation, key deletion). Event rules trigger SNS notifications to security operations team for time-sensitive events such as certificate expiration warnings or failed rotation attempts.

#### Service-to-service communication

1. **mTLS between application services**: Applications establish mTLS connections using certificates issued by ACM Private CA. Client presents its certificate during TLS handshake, server validates the certificate chain against the trusted root CA, and both parties verify the certificate has not been revoked using certificate revocation lists (CRLs) published by ACM Private CA.

2. **Agent to AWS API communication**: All communication between C# agent and AWS services uses TLS 1.3 with AWS Signature Version 4 (SigV4) authentication. API requests are signed using IAM role credentials with SHA-256 HMAC. AWS verifies the signature and evaluates IAM policies before processing the request.

### Components

The architecture consists of the following components:

#### Certificate and Key Management

- **AWS Certificate Manager Private Certificate Authority (ACM Private CA)**: Managed private certificate authority that issues X.509 certificates for internal mTLS authentication. Supports certificate templates for standardized certificate profiles, certificate revocation lists (CRLs) published to S3, and OCSP (Online Certificate Status Protocol) for real-time revocation checking. ACM Private CA stores CA private keys in AWS KMS HSMs with automatic key rotation every 90 days. Used in this architecture instead of self-managed PKI infrastructure to eliminate operational overhead of CA server maintenance, CRL distribution, and HSM management.

- **AWS Key Management Service (KMS)**: Fully managed service for creating and controlling cryptographic keys used to encrypt data. KMS provides FIPS 140-2 Level 3 validated hardware security modules (HSMs) for key storage with support for symmetric (AES-256-GCM) and asymmetric (RSA, ECC) keys. Supports automatic key rotation (yearly for symmetric keys), key policies for fine-grained access control, and envelope encryption for encrypting data encryption keys. AWS KMS integrates with CloudTrail to log all key usage including `Encrypt`, `Decrypt`, `GenerateDataKey` operations with caller identity and encryption context. Selected over AWS CloudHSM because KMS provides managed key infrastructure with native AWS service integration, while CloudHSM requires customer management of HSM clusters and key synchronization.

#### Secrets Management

- **AWS Secrets Manager**: Managed service for storing, retrieving, and rotating sensitive information such as database credentials, API keys, and OAuth tokens. Secrets are encrypted at rest using AWS KMS customer master keys (CMKs) with envelope encryption, versioned for rollback capabilities, and automatically rotated using Lambda functions. Secrets Manager supports fine-grained IAM policies with resource-based policies for cross-account access, VPC endpoints for private network access, and replication across AWS regions for disaster recovery. Integrates with Amazon RDS, Redshift, DocumentDB for automatic credential rotation without application downtime. Chosen over AWS Systems Manager Parameter Store (SecureString) because Secrets Manager provides built-in rotation, versioning with labels (`AWSCURRENT`, `AWSPREVIOUS`), and direct integration with database services.

- **AWS Lambda (for secret rotation)**: Serverless compute service executing secret rotation functions triggered by Secrets Manager. Lambda functions implement the rotation strategy pattern: create new secret version, update credentials in target system, verify new credentials, finalize rotation. Lambda execution role has IAM permissions for `GetSecretValue`, `PutSecretValue` to Secrets Manager and credentials update permissions to target systems (RDS, API Gateway). Lambda functions run in VPC with security group restrictions and timeout configured to 60 seconds to prevent long-running rotation failures.

#### Identity and Access Management

- **AWS Identity and Access Management (IAM)**: Service for managing authentication and authorization to AWS resources. IAM roles are assigned to EC2 instances hosting the C# agent, providing temporary credentials that automatically rotate every 6 hours. IAM policies follow least-privilege principle with conditions restricting access based on source IP, time of day, and multi-factor authentication status. Service control policies (SCPs) at AWS Organizations level prevent privilege escalation and enforce tagging requirements. IAM Access Analyzer continuously monitors policies for unintended external access.

- **AWS IAM Identity Center (successor to AWS SSO)**: Centralized identity service for administrator access to AWS accounts and applications. Integrates with corporate Active Directory or external identity providers (Okta, Azure AD) through SAML 2.0. Enforces multi-factor authentication (MFA) for all administrator sessions and supports time-based one-time passwords (TOTP) and FIDO2 hardware tokens. Permission sets define IAM policies applied to user groups with session duration limits (1-12 hours).

#### Compute and Agent Infrastructure

- **Amazon EC2 (Elastic Compute Cloud)**: Virtual servers hosting the C# secrets management agent. Instances run Windows Server 2019 or later with AWS Systems Manager Agent installed for patch management and remote access without SSH/RDP. Instance metadata service version 2 (IMDSv2) enforces token-based authentication preventing SSRF attacks. EC2 instances are launched in Auto Scaling groups with launch templates defining AMI ID, instance type, IAM role, and user data scripts for agent installation.

- **C# Secrets Management Agent**: Custom .NET application running as Windows service that orchestrates certificate retrieval from ACM Private CA, secret synchronization from Secrets Manager, and local storage in Windows Credential Manager. Agent implements exponential backoff retry logic for AWS API failures, maintains local cache of certificates and secrets with TTL expiration, and provides optional HTTP API (localhost only) for application access to secrets. Agent logs all operations to CloudWatch Logs and exposes Prometheus metrics for monitoring certificate expiration, secret retrieval latency, and error rates.

#### Local Secret Storage

- **Windows Credential Manager**: Operating system component providing secure storage for credentials in the Windows vault. Credentials are encrypted using Windows Data Protection API (DPAPI) which derives encryption keys from user logon credentials or system master keys stored in Local Security Authority (LSA). Credential Manager supports user-level credentials (accessible only to the logged-in user) and system-level credentials (accessible to services running as SYSTEM or LocalService). Access to credentials is controlled by Windows discretionary access control lists (DACLs) restricting read access to authorized service accounts.

#### Monitoring and Compliance

- **AWS CloudTrail**: Audit logging service recording all AWS API calls including caller identity, timestamp, source IP address, request parameters, and response elements. CloudTrail logs are immutable once delivered to S3, protected by S3 Object Lock in compliance mode preventing deletion even by root account. CloudTrail Insights detects unusual API activity patterns indicating potential security incidents such as excessive key decryption attempts or unauthorized certificate issuance.

- **Amazon CloudWatch**: Monitoring and observability service collecting metrics, logs, and traces from AWS services and C# agent. CloudWatch Logs Insights enables SQL-like queries across log groups for security analysis. CloudWatch Alarms trigger SNS notifications when metrics exceed thresholds (certificate expiration < 30 days, secret retrieval failures > 5%, KMS throttling). CloudWatch dashboards visualize certificate issuance rates, secret rotation success, and KMS key usage trends.

- **AWS Config**: Configuration management service continuously monitoring and recording AWS resource configurations. Config rules evaluate compliance against security baselines such as requiring KMS encryption on all Secrets Manager secrets, enforcing IMDSv2 on all EC2 instances, and validating ACM Private CA audit logging is enabled. Non-compliant resources trigger automatic remediation through AWS Systems Manager Automation documents or manual remediation workflows.

- **Amazon EventBridge**: Serverless event bus routing events from AWS services to targets such as Lambda, SNS, SQS. EventBridge rules capture certificate expiration events (30 days before expiry), secret rotation failures, and KMS key deletion attempts. Events are archived for 90 days and can be replayed for debugging or testing notification workflows.

### Key architectural decisions

| Decision point | Options considered | Chosen option | Rationale |
|----------------|-------------------|---------------|-----------|
| Certificate authority infrastructure | AWS Certificate Manager Private CA, Self-managed OpenSSL CA on EC2, AWS CloudHSM with EJBCA | ACM Private CA | ACM Private CA eliminates operational overhead of CA server management, automatic CRL publication, and HSM maintenance while providing managed infrastructure with 99.9% SLA. CloudHSM with EJBCA requires managing HSM clusters, CA software updates, and CRL distribution infrastructure. Self-managed OpenSSL CA introduces security risks from manual key management and lack of audit integration. ACM Private CA integrates natively with CloudTrail for comprehensive audit logging and supports automatic certificate renewal notifications. |
| Secret storage and rotation mechanism | AWS Secrets Manager, AWS Systems Manager Parameter Store (SecureString), HashiCorp Vault on ECS, Self-managed database | AWS Secrets Manager | Secrets Manager provides native rotation capabilities with Lambda integration, versioning with semantic labels (`AWSCURRENT`, `AWSPENDING`, `AWSPREVIOUS`) for zero-downtime rotation, and direct integration with RDS/Redshift for automatic credential updates. Parameter Store lacks built-in rotation requiring custom Lambda implementation and version labels. HashiCorp Vault requires operational overhead of cluster management, backup/restore, and Vault agent deployment. Secrets Manager meets SOC 2 requirements through AWS service compliance certifications while self-managed solutions require separate audit attestation. |
| Last-mile secret storage on Windows | Windows Credential Manager, File-based secrets with ACLs, In-memory only (no persistence), SQL Server LocalDB | Windows Credential Manager | Windows Credential Manager provides OS-native encrypted storage using DPAPI with hardware-backed encryption on TPM-equipped systems, integrated access control through Windows ACLs, and no external dependencies. File-based secrets expose plaintext credentials in memory during application read operations and require complex ACL management. In-memory storage requires secret retrieval on every application restart increasing AWS API costs and cold start latency. SQL Server LocalDB adds deployment complexity and requires separate encryption key management. Credential Manager is auditable through Windows Security Event Log (Event ID 5379 for credential access). |
| Agent implementation language | C# (.NET), Python (boto3), Go, PowerShell | C# (.NET 6+) | C# provides native Windows integration for Credential Manager APIs through P/Invoke or NuGet packages (CredentialManagement), mature AWS SDK with async/await support for high-performance API calls, and Windows service infrastructure through `BackgroundService` base class. Python requires pywin32 for Credential Manager access introducing binary dependencies. Go requires CGO for Windows API calls complicating cross-compilation. PowerShell lacks strong typing and structured error handling for production-grade agents. C# enables single executable deployment with PublishSingleFile and native AOT compilation reducing dependencies. |
| KMS key architecture | Single KMS key for all secrets, Separate KMS key per application, Separate KMS key per environment (dev/prod), Multi-region keys | Separate KMS key per environment | Separate keys per environment (development, staging, production) provide security isolation preventing developers from decrypting production secrets while allowing access to development secrets. Single key for all secrets creates excessive blast radius if key policy is misconfigured. Separate keys per application create key management overhead (100+ applications = 100+ keys) and complicate rotation automation. Multi-region keys are not required because this architecture uses Secrets Manager replication for disaster recovery which automatically re-encrypts secrets with the destination region's KMS key. Per-environment keys balance security isolation with operational simplicity. |
| Network connectivity pattern | Public internet with IAM authentication, VPC endpoints (PrivateLink), AWS Direct Connect only, VPN with AWS Client VPN | VPC endpoints (PrivateLink) | VPC endpoints for ACM Private CA, Secrets Manager, and KMS enable private connectivity without internet gateway or NAT gateway, reducing data transfer costs and eliminating public internet exposure. PrivateLink connections are authenticated through IAM policies with additional layer of security from VPC security groups restricting source IP ranges. AWS Direct Connect is not required for cloud-to-cloud communication and introduces high cost ($300+/month per connection). VPN adds latency (50-200ms) and throughput limitations (1.25 Gbps per tunnel). VPC endpoints support high throughput (10+ Gbps) and sub-5ms latency within region. |

## Alternatives and considerations

### Alternative 1: AWS CloudHSM with self-managed PKI

Replace ACM Private CA with AWS CloudHSM cluster running open-source certificate authority software (EJBCA, OpenSSL CA) to gain complete control over certificate templates, signing algorithms, and key storage.

**When to use**:
- Regulatory requirements mandate physical control over cryptographic operations with FIPS 140-2 Level 3 certification for the entire key lifecycle
- Custom certificate extensions or signing algorithms not supported by ACM Private CA are required (e.g., custom OIDs, Attribute Certificates)
- Certificate signing requests require complex validation workflows involving external approval systems or manual verification

**Trade-offs**:
- :::image type="icon" source="../_images/trade-off.svg"::: Operational complexity increases significantly requiring management of HSM clusters (minimum 2 HSMs for high availability), CA software patching, and CRL/OCSP responder infrastructure
- :::image type="icon" source="../_images/trade-off.svg"::: Cost increases by approximately $5,000/month for multi-AZ CloudHSM cluster compared to $400/month for ACM Private CA
- :::image type="icon" source="../_images/trade-off.svg"::: Audit integration requires custom CloudTrail integration through CloudHSM client SDK instead of native ACM Private CA audit logging

**Impact**:
- **Cost**: $5,400/month (CloudHSM cluster + EC2 for CA software) vs. $400/month (ACM Private CA)
- **Operations**: Full responsibility for HSM cluster management, CA software updates, key backup/restore, and CRL distribution
- **Performance**: Similar latency (sub-100ms for certificate issuance) but requires capacity planning for HSM cluster throughput

### Alternative 2: HashiCorp Vault on AWS ECS

Deploy HashiCorp Vault on Amazon ECS Fargate to provide unified secrets management with dynamic secrets, certificate issuance through Vault PKI engine, and integration with non-AWS systems.

**When to use**:
- Multi-cloud secrets management is required with secrets synchronized across AWS, Azure, and Google Cloud Platform
- Dynamic database credentials with time-limited leases are necessary (Vault generates unique credentials per application with automatic revocation)
- Existing HashiCorp ecosystem with Terraform Cloud integration for secrets injection into infrastructure provisioning workflows

**Trade-offs**:
- :::image type="icon" source="../_images/trade-off.svg"::: Operational complexity of managing Vault cluster including Consul or Integrated Storage for high availability, unsealing procedures, and snapshot backups
- :::image type="icon" source="../_images/trade-off.svg"::: Cost of ECS Fargate compute for Vault servers ($150-300/month for 3-node cluster) plus Application Load Balancer ($25/month) compared to pay-per-request pricing of Secrets Manager
- :::image type="icon" source="../_images/trade-off.svg"::: Loss of native AWS service integration requiring custom code for secret rotation in RDS and Redshift

**Impact**:
- **Cost**: $200-350/month (Vault infrastructure) + $0.05 per 10,000 secret requests vs. $0.40 per secret per month (Secrets Manager) + $0.05 per 10,000 requests
- **Operations**: Requires Vault expertise for cluster management, policy administration, and troubleshooting
- **Compliance**: SOC 2 compliance requires separate audit of self-managed Vault infrastructure while AWS Secrets Manager inherits AWS SOC 2 certification

### Alternative 3: AWS Certificate Manager public certificates for mTLS

Use AWS Certificate Manager public certificates issued by Amazon Trust Services CA instead of ACM Private CA for mTLS authentication.

**When to use**: Not recommended for this scenario.

**Trade-offs**:
- :::image type="icon" source="../_images/trade-off.svg"::: ACM public certificates are intended for public-facing TLS (HTTPS websites, APIs) and cannot be exported with private keys, preventing client-side mTLS authentication
- :::image type="icon" source="../_images/trade-off.svg"::: ACM public certificates require domain validation through DNS or email, which is impractical for internal service names (service-a.internal.corp)
- :::image type="icon" source="../_images/risk.svg"::: **Risk**: Using public certificates for internal services exposes internal DNS names in Certificate Transparency logs, disclosing network topology to potential attackers

**Impact**: This alternative is not viable for mTLS use cases. Use ACM Private CA for internal services or external certificate authorities with exportable certificates for client authentication.

### Variation 1: Multi-region deployment for disaster recovery

Deploy ACM Private CA, Secrets Manager, and KMS infrastructure across multiple AWS regions (e.g., us-east-1 primary, us-west-2 secondary) with cross-region secret replication and Route 53 failover policies.

**Implementation**:
- Enable Secrets Manager cross-region replication for critical secrets with automatic re-encryption using destination region KMS keys
- Deploy ACM Private CA in secondary region as subordinate CA to primary region root CA, enabling certificate issuance during regional outage
- Configure C# agent with multi-region endpoint awareness using Route 53 health checks and failover routing policies
- Implement bi-directional secret synchronization for regionally deployed secrets (database connection strings, region-specific API keys)

**When to use**:
- Business continuity requirements mandate RTO < 1 hour and RPO < 5 minutes for certificate issuance and secret retrieval
- Applications are deployed across multiple AWS regions with regional data sovereignty requirements
- Disaster recovery testing requires full regional failover without manual intervention

**Impact on cost**: Additional $400/month for secondary region ACM Private CA + Secrets Manager replication data transfer costs ($0.01/GB)

### Variation 2: Hardware Security Module (HSM) integration for KMS

Replace software-backed KMS keys with AWS CloudHSM for FIPS 140-2 Level 3 certified hardware key storage across all cryptographic operations.

**Implementation**:
- Deploy CloudHSM cluster with minimum 2 HSMs in separate availability zones
- Configure KMS custom key store backed by CloudHSM cluster for secrets encryption
- Modify C# agent to support CloudHSM client library for direct cryptographic operations
- Implement HSM key backup to encrypted S3 bucket with multi-party quorum for key restoration

**When to use**:
- Compliance requirements mandate physical control over key storage with audit evidence of hardware key generation
- Regulatory frameworks require key ownership with provable key destruction capabilities
- Ultra-high-security workloads requiring cryptographic performance beyond KMS rate limits (1,000+ TPS per key)

**Impact on cost**: Additional $5,000/month for CloudHSM cluster infrastructure

## Recommendations

The following recommendations apply to most scenarios. Follow these recommendations unless you have a specific requirement that overrides them.

### Reliability

:::image type="icon" source="../_images/goal.svg"::: **Design for 99.9% availability with multi-AZ deployment and automated failover**

| Recommendation | Benefit |
|----------------|---------|
| **Deploy ACM Private CA with automatic CRL publication to S3**: Configure CRL publication interval to 1 hour and enable S3 bucket replication to secondary region | Ensures certificate revocation status remains available during S3 outages; multi-region replication provides disaster recovery capability with RTO < 5 minutes |
| **Enable Secrets Manager multi-region replication for critical secrets**: Replicate production database credentials and API keys to secondary AWS region with automatic KMS re-encryption | Maintains secret availability during regional AWS outages; replication lag < 5 seconds enables near-synchronous disaster recovery |
| **Deploy C# agent in Auto Scaling group with minimum 2 instances per AZ**: Configure Application Load Balancer health checks on agent API endpoint with 30-second intervals | Provides automatic replacement of failed agent instances; multi-AZ deployment survives datacenter-level failures with zero manual intervention |
| **Implement exponential backoff retry logic in C# agent for all AWS API calls**: Use AWS SDK built-in retry logic with 3 attempts and exponential backoff (1s, 2s, 4s) | Handles transient AWS API throttling and network failures gracefully; prevents cascading failures during AWS service degradations |
| **Cache certificates and secrets locally with TTL expiration**: Store retrieved certificates in memory cache for 12 hours (50% of 24-hour certificate validity) and secrets for 5 minutes | Reduces dependency on AWS API availability for secret retrieval; provides degraded mode operation during AWS outages with stale but valid secrets |

#### High availability

Deploy all AWS managed services (ACM Private CA, Secrets Manager, KMS) with multi-AZ configuration to protect against availability zone failures:

- **ACM Private CA**: Automatically distributed across multiple AZs by AWS with no configuration required; 99.9% SLA
- **Secrets Manager**: Multi-AZ by default with automatic replication across AZs; secrets remain accessible during AZ failures
- **KMS**: Multi-AZ with automatic key replication; supports 1,000 requests per second per key in single region with burst capacity to 5,000 TPS
- **EC2 Auto Scaling for C# agent**: Deploy instances across 3 availability zones with minimum 2 instances per AZ (6 total) to maintain capacity during AZ failure

Configure health checks at every tier:
- **Application Load Balancer**: HTTP health check on `/health` endpoint returning certificate expiration status and last successful secret sync timestamp
- **Auto Scaling group**: EC2 instance status checks (system reachability, instance reachability) with 2-minute grace period before instance termination
- **C# agent internal health checks**: Monitor certificate validity, secret cache staleness, and AWS API connectivity every 60 seconds

#### Disaster recovery

Implement automated disaster recovery with defined RTO (Recovery Time Objective) and RPO (Recovery Point Objective):

**RTO Target: 15 minutes**
- Use AWS Secrets Manager cross-region replication for automated secret availability in secondary region
- Deploy ACM Private CA in secondary region as subordinate CA to primary region root CA
- Maintain warm standby of C# agent Auto Scaling group in secondary region with minimum 1 instance per AZ (scaled up during failover)

**RPO Target: 5 minutes**
- Secrets Manager replication lag < 5 seconds ensures near-zero data loss for secret updates
- Certificate issuance is stateless; secondary region ACM Private CA issues new certificates immediately upon failover
- CloudTrail logs delivered to S3 within 5 minutes ensure complete audit trail with minimal gap during regional outage

**Failover procedure**:
1. Route 53 health check detects primary region ACM Private CA endpoint failure (3 consecutive failures over 90 seconds)
2. Route 53 failover policy updates DNS to point to secondary region ACM Private CA and Secrets Manager endpoints
3. Auto Scaling group in secondary region scales out to match primary region capacity (scaling completes within 5 minutes)
4. C# agent instances in secondary region begin issuing certificates and retrieving secrets using regional endpoints
5. CloudWatch alarm notifies operations team of failover event

Test disaster recovery procedures quarterly using Route 53 Application Recovery Controller or manual Route 53 record updates.

#### Resilience patterns

Implement circuit breaker pattern for AWS API calls in C# agent:

```csharp
// Circuit breaker opens after 5 consecutive failures, remains open for 60 seconds
var circuitBreakerPolicy = Policy
    .Handle<AmazonServiceException>()
    .CircuitBreakerAsync(5, TimeSpan.FromSeconds(60));
```

Implement retry logic with exponential backoff and jitter:

```csharp
var retryPolicy = Policy
    .Handle<AmazonServiceException>(ex => ex.StatusCode == System.Net.HttpStatusCode.ServiceUnavailable)
    .WaitAndRetryAsync(3,
        retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt))
                      + TimeSpan.FromMilliseconds(new Random().Next(0, 1000)));
```

Implement bulkhead isolation to prevent resource exhaustion:

- Separate thread pools for certificate retrieval (5 threads), secret retrieval (10 threads), and API server (20 threads)
- Per-operation timeouts: certificate issuance (30s), secret retrieval (10s), KMS decryption (5s)
- Rate limiting on agent API endpoints: 100 requests per second per instance with token bucket algorithm

### Security

:::image type="icon" source="../_images/goal.svg"::: **Design for zero-trust security with defense-in-depth encryption, IAM least privilege, and comprehensive audit logging**

| Recommendation | Benefit |
|----------------|---------|
| **Enable KMS automatic key rotation for all customer master keys**: Configure annual rotation for symmetric encryption keys used by Secrets Manager and ACM Private CA | Limits cryptographic exposure period to 1 year; automatic rotation occurs transparently without re-encrypting existing secrets (KMS maintains all historical key versions) |
| **Enforce IMDSv2 on all EC2 instances hosting C# agent**: Configure launch template with `HttpTokens=required` and `HttpPutResponseHopLimit=1` | Prevents SSRF attacks targeting instance metadata service; token-based authentication ensures only local processes can retrieve IAM credentials |
| **Implement least-privilege IAM policies with resource-level permissions**: Restrict certificate issuance to specific ACM Private CA ARN and secret retrieval to specific secret ARN prefixes (e.g., `arn:aws:secretsmanager:*:*:secret:prod/*`) | Prevents lateral movement; compromised agent credentials cannot access secrets from different environments or issue certificates from unauthorized CAs |
| **Enable CloudTrail log file validation and S3 Object Lock**: Configure Object Lock in compliance mode with 7-year retention preventing deletion by any principal including root account | Ensures immutability of audit logs meeting SOC 2 evidence preservation requirements; log file validation detects tampering through SHA-256 hash verification |
| **Use VPC endpoints for all AWS API communication**: Deploy interface endpoints for ACM Private CA, Secrets Manager, KMS, and gateway endpoints for S3 | Eliminates public internet exposure for certificate and secret retrieval; VPC security groups provide network-level access control restricting source IP ranges |

#### Identity and access management

Implement role-based access control with IAM roles and policies:

**C# Agent IAM Role** (`arn:aws:iam::123456789012:role/SecretAgentRole`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IssueCertificates",
      "Effect": "Allow",
      "Action": [
        "acm-pca:IssueCertificate",
        "acm-pca:GetCertificate"
      ],
      "Resource": "arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/abcd1234-5678-90ab-cdef-EXAMPLE11111",
      "Condition": {
        "StringEquals": {
          "acm-pca:TemplateArn": "arn:aws:acm-pca:::template/EndEntityCertificate/V1"
        }
      }
    },
    {
      "Sid": "RetrieveSecrets",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/*",
      "Condition": {
        "StringEquals": {
          "secretsmanager:VersionStage": "AWSCURRENT"
        }
      }
    },
    {
      "Sid": "DecryptWithKMS",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
      "Condition": {
        "StringEquals": {
          "kms:EncryptionContext:SecretARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/*"
        }
      }
    }
  ]
}
```

**Administrator IAM Policy** (read-only access to audit logs, no key management permissions):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyMonitoring",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:LookupEvents",
        "cloudwatch:GetMetricData",
        "logs:FilterLogEvents",
        "config:GetComplianceDetailsByConfigRule"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyKeyManagement",
      "Effect": "Deny",
      "Action": [
        "kms:ScheduleKeyDeletion",
        "kms:DisableKey",
        "secretsmanager:DeleteSecret",
        "acm-pca:DeleteCertificateAuthority"
      ],
      "Resource": "*"
    }
  ]
}
```

Enforce multi-factor authentication (MFA) for all administrative actions:
```json
{
  "Condition": {
    "BoolIfExists": {
      "aws:MultiFactorAuthPresent": "true"
    },
    "NumericLessThan": {
      "aws:MultiFactorAuthAge": "3600"
    }
  }
}
```

Use AWS IAM Access Analyzer to detect overly permissive policies:
- Enable Access Analyzer at AWS Organizations level to scan all member accounts
- Configure analyzer to alert on external access (cross-account resource sharing)
- Review unused access findings quarterly and remove unused permissions

#### Network security

Implement private network connectivity for all AWS API communication:

**VPC Endpoints** (AWS PrivateLink):
- Interface endpoints: ACM Private CA (`com.amazonaws.us-east-1.acm-pca`), Secrets Manager (`com.amazonaws.us-east-1.secretsmanager`), KMS (`com.amazonaws.us-east-1.kms`), CloudWatch Logs (`com.amazonaws.us-east-1.logs`)
- Gateway endpoints: S3 (for CRL downloads and CloudTrail log delivery)
- Endpoint policy restricts access to specific resource ARNs within the account

**Security Group Configuration**:
```
# C# Agent Security Group (sg-agent)
Inbound:
  - HTTPS (443) from Application Load Balancer security group (sg-alb)
  - HTTPS (443) from VPC CIDR 10.0.0.0/8 for agent API access
Outbound:
  - HTTPS (443) to VPC Endpoint security group (sg-vpce)
  - No outbound internet access (0.0.0.0/0 denied)

# VPC Endpoint Security Group (sg-vpce)
Inbound:
  - HTTPS (443) from Agent security group (sg-agent)
Outbound:
  - None (managed by AWS)
```

**Network ACLs** (stateless firewall):
- Allow inbound HTTPS (443) from VPC CIDR blocks
- Allow ephemeral ports (1024-65535) for return traffic
- Deny all other inbound traffic
- Allow all outbound traffic to VPC endpoints

**Private DNS for VPC Endpoints**:
- Enable private DNS names for interface endpoints so AWS SDK resolves `secretsmanager.us-east-1.amazonaws.com` to VPC endpoint private IP (10.0.5.100) instead of public IP
- Eliminates need for SDK configuration changes to use VPC endpoints

#### Data protection

Implement encryption at rest and in transit for all sensitive data:

**Encryption at Rest**:
- **AWS Secrets Manager**: All secrets encrypted with AWS KMS using customer-managed key (CMK) with AES-256-GCM encryption algorithm
- **ACM Private CA**: CA private keys stored encrypted in AWS KMS FIPS 140-2 Level 3 validated hardware security modules
- **Windows Credential Manager**: Credentials encrypted using Windows Data Protection API (DPAPI) with AES-256-CBC and machine-specific or user-specific key derivation
- **CloudWatch Logs**: Log groups encrypted with KMS customer-managed key with separate key per environment (dev, staging, prod)
- **S3 (CloudTrail logs, CRL storage)**: Server-side encryption with KMS (SSE-KMS) using separate key for audit logs

**Encryption in Transit**:
- **TLS 1.3** for all AWS API communication with cipher suites: `TLS_AES_128_GCM_SHA256`, `TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`
- **mTLS** between applications using certificates issued by ACM Private CA with client certificate authentication and mutual verification
- **Certificate pinning** in C# agent pinning AWS API endpoints to Amazon root CA (Amazon Root CA 1, Amazon Root CA 2) preventing MITM attacks

**Key Management**:
- Use separate KMS keys per environment (development, staging, production) to prevent cross-environment secret access
- Enable automatic key rotation (365-day interval) for symmetric encryption keys
- Configure key policies with least-privilege access using IAM role ARNs and conditions restricting key usage to specific encryption contexts
- Export KMS key metadata (not key material) to S3 for disaster recovery documentation

**Secrets Manager encryption context**:
```json
{
  "aws:secretsmanager:SecretARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/database-password-AbCdEf",
  "environment": "production",
  "application": "web-api"
}
```

#### Application security

Implement secure coding practices and vulnerability management:

**C# Agent Security Measures**:
- Input validation on all API endpoints using data annotations (`[Required]`, `[StringLength]`, `[RegularExpression]`)
- Output encoding when logging secret metadata (log secret ARN and version, never log secret values)
- Dependency scanning using `dotnet list package --vulnerable` integrated into CI/CD pipeline
- Static analysis using Roslyn analyzers (SecurityCodeScan.NET) to detect SQL injection, XSS, and insecure deserialization
- Secrets never stored in application memory as strings; use `SecureString` or byte arrays with explicit zeroing after use

**Windows Credential Manager Security**:
- Store credentials with `CRED_TYPE_GENERIC` type and `CRED_PERSIST_LOCAL_MACHINE` persistence for system-level secrets
- Set credential ACLs restricting read access to specific service accounts: `NT AUTHORITY\SYSTEM`, `NT SERVICE\SecretAgentService`
- Enable Windows Security Event Log auditing for credential access (Event ID 5379: Credential Manager credentials were read)

**Secret rotation validation**:
- Lambda rotation function validates new credentials by establishing test connection to target system (database, API) before marking rotation complete
- Failed rotation attempts trigger rollback to previous secret version (`AWSPREVIOUS` label) and SNS notification to operations team
- Rotation functions run with minimal IAM permissions and VPC security groups restricting access to target systems

**Vulnerability Management**:
- Enable Amazon Inspector for automated vulnerability scanning of EC2 instances hosting C# agent
- Configure AWS Systems Manager Patch Manager for automatic OS patching with 7-day delay after patch release (to allow vendor testing)
- Implement AWS Security Hub for aggregated security findings across Config rules, GuardDuty, and Inspector

#### Monitoring and threat detection

Implement comprehensive logging and real-time threat detection:

**CloudTrail Audit Logging**:
- Enable CloudTrail organization trail capturing events from all AWS accounts
- Log all management events (read + write) and data events for S3 (CRL downloads) and Secrets Manager (GetSecretValue)
- Configure CloudTrail Insights to detect unusual API activity patterns (e.g., excessive KMS Decrypt calls indicating potential secret exfiltration)

**GuardDuty Threat Detection**:
- Enable Amazon GuardDuty for intelligent threat detection using machine learning models analyzing CloudTrail logs, VPC Flow Logs, and DNS logs
- Configure GuardDuty findings for critical severity to trigger SNS notifications and Lambda automated response (e.g., rotate secrets, disable IAM role)
- Monitor for findings: `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration`, `Stealth:IAMUser/LoggingConfigurationModified`

**CloudWatch Logs Insights Queries**:

**Failed secret retrieval attempts**:
```
fields @timestamp, userIdentity.principalId, requestParameters.secretId, errorCode
| filter eventName = "GetSecretValue" and errorCode exists
| stats count() by errorCode, userIdentity.principalId
| sort count desc
```

**Certificate issuance rate anomaly detection**:
```
fields @timestamp, requestParameters.certificateAuthorityArn
| filter eventName = "IssueCertificate"
| stats count() as issuance_count by bin(5m)
| sort @timestamp desc
```

**KMS key usage by service**:
```
fields @timestamp, userIdentity.invokedBy, requestParameters.keyId, resources.0.arn
| filter eventName = "Decrypt"
| stats count() by userIdentity.invokedBy, requestParameters.keyId
```

**Real-time Alerting**:
- CloudWatch Alarm: Certificate expiration < 30 days (metric filter on ACM Private CA logs) → SNS topic → PagerDuty
- CloudWatch Alarm: Secret rotation failures > 2 in 24 hours (metric filter on Lambda logs) → SNS topic → Slack
- EventBridge rule: KMS key deletion scheduled → SNS topic → Security team email (requires multi-party approval to confirm deletion)

### Cost Optimization

:::image type="icon" source="../_images/goal.svg"::: **Design for cost-effective operations with right-sized resources and usage-based billing**

| Recommendation | Benefit |
|----------------|---------|
| **Use ACM Private CA in short-lived certificate mode**: Configure certificates with 1-7 day validity instead of 1-year validity to leverage lower pricing tier ($0.75 per certificate vs. $1.00) | Reduces certificate issuance cost by 25%; shorter validity periods improve security posture by limiting compromise window |
| **Implement secret caching in C# agent with 5-minute TTL**: Cache frequently accessed secrets in agent memory to minimize Secrets Manager API calls | Reduces Secrets Manager costs from $0.05 per 10,000 API calls; caching 100 agents polling every 30 seconds reduces monthly cost from $216 to $4.32 |
| **Right-size EC2 instances based on agent workload**: Use t3.micro instances (2 vCPU, 1GB RAM) for agent deployment with AWS Compute Optimizer recommendations | Reduces compute cost from $35/month (t3.small) to $8/month (t3.micro) per instance; agent requires <500MB RAM and minimal CPU |
| **Enable S3 Intelligent-Tiering for CRL storage**: Configure S3 lifecycle policy moving CRLs to Infrequent Access tier after 30 days and Archive Access after 90 days | Reduces storage cost by 68% for CRLs older than 90 days ($0.023/GB for Standard to $0.0036/GB for Archive Access); CRLs accessed infrequently after initial publication |
| **Use AWS Compute Savings Plans for EC2 instances**: Commit to 1-year or 3-year Savings Plan for consistent agent compute workload with 20% usage on t3.micro instances | Reduces EC2 costs by 33% (1-year plan) to 52% (3-year plan); agent workload is predictable making reserved capacity cost-effective |

#### Resource optimization

Right-size resources based on actual utilization metrics:

**EC2 Instance Sizing**:
- Monitor CPU utilization, memory utilization, and network throughput for 30 days using CloudWatch
- Use AWS Compute Optimizer recommendations to identify under-provisioned (CPU >70% sustained) or over-provisioned (CPU <10% average) instances
- Target utilization: 40-60% CPU average with burst capacity for peak certificate issuance periods

**ACM Private CA Certificate Validity**:
- Use 7-day certificates for high-security environments requiring frequent rotation ($0.75 per certificate with 52 renewals/year = $39/year per service)
- Use 90-day certificates for standard environments balancing security and cost ($1.00 per certificate with 4 renewals/year = $4/year per service)
- Evaluate trade-off: shorter validity improves security but increases issuance costs and renewal frequency

**Secrets Manager Secret Count**:
- Consolidate related secrets into single JSON secret value (e.g., database connection string with username + password + host in single secret)
- Monthly cost: $0.40 per secret + $0.05 per 10,000 API calls
- Consolidating 10 related secrets into 1 JSON secret reduces cost from $4.00/month to $0.40/month (90% reduction)

**KMS Key Consolidation**:
- Use single KMS key per environment (development, staging, production) instead of per-application keys
- Monthly cost: $1.00 per key + $0.03 per 10,000 requests
- Consolidating 50 application-specific keys to 3 environment keys reduces cost from $50/month to $3/month (94% reduction)
- :::image type="icon" source="../_images/trade-off.svg"::: Key consolidation reduces security isolation between applications; evaluate risk vs. cost trade-off

#### Operational efficiency

Automate cost optimization through infrastructure as code:

**Secrets Manager Lifecycle Management**:
- Delete unused secrets after 30-day recovery window to stop incurring $0.40/month per secret charge
- Tag secrets with `LastAccessDate` using Lambda function analyzing CloudTrail logs; flag secrets with no access in 90 days for review
- Implement approval workflow for new secret creation using AWS Service Catalog to prevent secret sprawl

**Development Environment Cost Reduction**:
- Use ACM Private CA in development environment during business hours only (8am-6pm weekdays) saving 72% of monthly cost ($400/month to $112/month)
- Use automation (EventBridge scheduled rule → Lambda) to delete/recreate ACM Private CA in development environment
- :::image type="icon" source="../_images/trade-off.svg"::: Development environment unavailability outside business hours; acceptable for non-production workloads

**CloudWatch Logs Retention**:
- Configure log group retention based on compliance requirements and access patterns:
  - Production CloudTrail logs: 7 years (SOC 2 requirement)
  - Application logs: 90 days (operational troubleshooting)
  - Development logs: 7 days (cost optimization)
- Monthly cost: $0.50/GB ingested + $0.03/GB stored
- Reducing retention from 90 days to 7 days for development logs reduces storage cost by 92%

#### Monitoring and governance

Implement cost monitoring and alerting:

**AWS Cost Explorer Analysis**:
- Group costs by service: ACM Private CA, Secrets Manager, KMS, EC2, CloudWatch
- Filter by tag: `Environment=production`, `Application=secrets-management`
- Identify cost trends: increasing certificate issuance rates, secret count growth, CloudWatch Logs volume

**AWS Budgets**:
- Create budget for secrets management infrastructure: $1,000/month threshold
- Configure alerts at 80% ($800), 90% ($900), and 100% ($1,000) of budget
- Forecast alerts when projected spend exceeds budget by end of month

**Cost Allocation Tags**:
```
Environment: production | staging | development
Application: secrets-management
CostCenter: security-infrastructure
Owner: platform-engineering-team
```

**Right-sizing Recommendations**:
- Enable AWS Compute Optimizer for EC2 instance recommendations
- Review recommendations monthly during architecture review meetings
- Implement approved recommendations through infrastructure-as-code changes

**Cost Anomaly Detection**:
- Enable AWS Cost Anomaly Detection with machine learning models identifying unusual spend patterns
- Configure alerts for anomalies >$100 above baseline (e.g., unexpected increase in certificate issuance or secret API calls)
- Investigate anomalies within 24 hours to identify misconfigurations or security incidents (e.g., compromised credentials leading to excessive API usage)

### Operational Excellence

:::image type="icon" source="../_images/goal.svg"::: **Design for automated operations with infrastructure as code, comprehensive monitoring, and safe deployment practices**

| Recommendation | Benefit |
|----------------|---------|
| **Deploy all infrastructure using Terraform or AWS CloudFormation**: Define ACM Private CA, Secrets Manager secrets, KMS keys, IAM roles, and VPC endpoints in declarative infrastructure-as-code | Enables version-controlled infrastructure changes with peer review; provides repeatable deployments across environments (dev, staging, prod) with environment-specific parameters |
| **Implement automated certificate renewal 30 days before expiration**: Configure EventBridge rule triggering Lambda function to notify certificate owners 30 days before expiry | Prevents service outages from expired certificates; provides sufficient time for testing renewed certificates before production deployment |
| **Use AWS Systems Manager Parameter Store for agent configuration**: Store agent settings (polling intervals, cache TTL, log levels) in Parameter Store with versioning | Enables centralized configuration management without agent redeployment; supports dynamic configuration updates with agent polling Parameter Store every 5 minutes |
| **Implement blue/green deployment for C# agent updates**: Deploy new agent version to separate Auto Scaling group, validate functionality, then shift traffic using Application Load Balancer target group weighting | Enables zero-downtime agent updates with instant rollback capability; validates new version with production traffic before full cutover |
| **Configure CloudWatch dashboards for operational visibility**: Create dashboards showing certificate expiration timeline, secret rotation success rate, KMS API latency, and agent health metrics | Provides at-a-glance operational status for on-call engineers; enables proactive issue detection before customer impact |

#### Infrastructure as Code

Use Terraform for declarative infrastructure definition:

**Terraform Module Structure**:
```
terraform/
├── modules/
│   ├── acm-pca/
│   │   ├── main.tf              # ACM Private CA resource definition
│   │   ├── variables.tf          # Input variables (CA validity, certificate template)
│   │   └── outputs.tf            # Outputs (CA ARN, CRL endpoint)
│   ├── secrets-manager/
│   │   ├── main.tf              # Secret resource and rotation configuration
│   │   ├── variables.tf          # Input variables (secret name, rotation lambda ARN)
│   │   └── outputs.tf            # Outputs (secret ARN, secret version)
│   ├── kms/
│   │   ├── main.tf              # KMS key and key policy definition
│   │   ├── variables.tf          # Input variables (key description, rotation enabled)
│   │   └── outputs.tf            # Outputs (key ID, key ARN)
│   └── agent-infrastructure/
│       ├── main.tf              # EC2 Auto Scaling, ALB, security groups
│       ├── variables.tf          # Input variables (instance type, AMI ID)
│       └── outputs.tf            # Outputs (ALB DNS name, agent endpoint)
├── environments/
│   ├── production/
│   │   ├── main.tf              # Production environment configuration
│   │   └── terraform.tfvars      # Production-specific variables
│   ├── staging/
│   │   └── main.tf
│   └── development/
│       └── main.tf
└── backend.tf                   # S3 backend for Terraform state with DynamoDB locking
```

**Terraform Backend Configuration** (state locking for team collaboration):
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-secrets-mgmt"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/terraform-state-key"
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Module Example** (ACM Private CA):
```hcl
module "acm_pca" {
  source = "../../modules/acm-pca"

  ca_common_name   = "Internal Services Root CA"
  ca_organization  = "Example Corp"
  ca_validity_days = 3650  # 10 years

  certificate_template_arn = "arn:aws:acm-pca:::template/EndEntityCertificate/V1"

  crl_enabled            = true
  crl_expiration_days    = 7
  crl_s3_bucket_name     = "example-corp-crl-bucket"

  tags = {
    Environment = "production"
    Application = "secrets-management"
  }
}
```

**Configuration Management**:
- Store environment-specific variables in `terraform.tfvars` files (not committed to version control)
- Use AWS Systems Manager Parameter Store for sensitive values (KMS key IDs, secret ARNs) loaded into Terraform using data sources
- Implement Terraform workspaces for environment isolation: `terraform workspace select production`

#### Deployment

Implement CI/CD pipeline for automated agent deployment:

**GitHub Actions Workflow** (`.github/workflows/deploy-agent.yml`):
```yaml
name: Deploy Secrets Management Agent

on:
  push:
    branches: [main]
    paths:
      - 'src/SecretAgent/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '6.0.x'

      - name: Build agent
        run: dotnet publish src/SecretAgent/SecretAgent.csproj -c Release -o ./publish

      - name: Run security scan
        run: dotnet list package --vulnerable --include-transitive

      - name: Create deployment package
        run: |
          cd publish
          zip -r ../agent-${{ github.sha }}.zip .

      - name: Upload to S3
        run: |
          aws s3 cp agent-${{ github.sha }}.zip s3://agent-deployments-bucket/

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Update Auto Scaling launch template
        run: |
          aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name secrets-agent-staging \
            --launch-template LaunchTemplateName=agent-template,Version='$Latest'

      - name: Trigger instance refresh
        run: |
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name secrets-agent-staging \
            --preferences MinHealthyPercentage=90,InstanceWarmup=300

      - name: Wait for instance refresh completion
        run: |
          aws autoscaling describe-instance-refreshes \
            --auto-scaling-group-name secrets-agent-staging \
            --query 'InstanceRefreshes[0].Status' \
            --output text | grep -q 'Successful'

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      # Same deployment steps as staging with production ASG name
      # Requires manual approval configured in GitHub Actions environment settings
```

**Blue/Green Deployment Strategy**:
1. Create new launch template version with updated agent AMI
2. Create new Auto Scaling group (green) with new launch template pointing to existing Application Load Balancer
3. Scale green Auto Scaling group to match blue capacity (6 instances across 3 AZs)
4. Wait for all green instances to pass health checks (5-minute warmup period)
5. Shift 10% of traffic to green target group using ALB target group weighting
6. Monitor error rates and latency for 30 minutes
7. Incrementally shift traffic: 10% → 25% → 50% → 100% with 30-minute observation periods
8. Decommission blue Auto Scaling group after 24 hours (allowing rollback window)

**Rollback Procedure**:
1. Detect deployment failure through CloudWatch alarms (error rate >1%, latency >5 seconds)
2. Shift all traffic back to blue target group (previous version) using ALB console or CLI
3. Scale down green Auto Scaling group to 0 instances
4. Investigate deployment failure through CloudWatch Logs and AWS X-Ray traces
5. Fix issue in agent code or configuration and trigger new deployment

#### Monitoring and observability

Implement comprehensive monitoring with structured logging:

**CloudWatch Dashboards**:

**Certificate Management Dashboard**:
- Line chart: Certificates issued per hour (ACM Private CA API calls)
- Number widget: Certificates expiring within 30 days
- Number widget: Certificates expiring within 7 days (critical alert threshold)
- Line chart: Certificate issuance latency (p50, p95, p99 percentiles)
- Pie chart: Certificates by organizational unit (OU) showing application distribution

**Secrets Management Dashboard**:
- Line chart: Secret retrieval rate per minute (GetSecretValue API calls)
- Bar chart: Secret rotation success/failure count by secret name
- Number widget: Secrets pending rotation (rotation scheduled but not completed)
- Line chart: KMS decryption latency (p50, p95, p99)
- Heatmap: Secret access patterns by hour of day and day of week

**Agent Health Dashboard**:
- Line chart: Agent instance count by Auto Scaling group and availability zone
- Line chart: Agent API response time (p50, p95, p99) from ALB access logs
- Number widget: Failed health checks in last 24 hours
- Line chart: Agent memory utilization and CPU utilization across instances
- Log insights widget: Top 10 error messages from agent logs in last hour

**Structured Logging Format** (JSON logs for CloudWatch Logs Insights):
```json
{
  "timestamp": "2025-01-11T15:30:00.000Z",
  "level": "INFO",
  "logger": "SecretAgent.CertificateManager",
  "message": "Certificate issued successfully",
  "certificateArn": "arn:aws:acm-pca:us-east-1:123456789012:certificate/abc123...",
  "commonName": "service-a.internal.example.com",
  "validityDays": 7,
  "issuanceLatencyMs": 250,
  "requestId": "8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f"
}
```

**CloudWatch Logs Insights Queries**:

**Top 10 slowest secret retrievals**:
```
fields @timestamp, secretArn, latencyMs
| filter logger = "SecretAgent.SecretsManager" and message = "Secret retrieved"
| sort latencyMs desc
| limit 10
```

**Error rate by operation**:
```
fields @timestamp, operation, errorType
| filter level = "ERROR"
| stats count() as errorCount by operation, errorType
| sort errorCount desc
```

**AWS X-Ray Distributed Tracing**:
- Instrument C# agent with AWS X-Ray SDK to capture trace data for certificate issuance and secret retrieval workflows
- Visualize service map showing agent → ACM Private CA → KMS → Secrets Manager call chains with latency breakdown
- Identify bottlenecks: 70% time in KMS decryption vs. 20% in network latency vs. 10% in agent processing
- Set up sampling rules: 100% tracing for failed requests, 5% sampling for successful requests to control costs

#### Operations procedures

Document and automate operational runbooks:

**Certificate Expiration Response**:
1. **Detection**: CloudWatch alarm triggers when certificate expiration < 7 days
2. **Notification**: SNS topic sends email to platform engineering team with certificate ARN and expiration date
3. **Automated renewal**: EventBridge rule triggers Lambda function issuing new certificate from ACM Private CA with identical subject DN
4. **Deployment**: Lambda function uploads new certificate to Secrets Manager secret for retrieval by affected services
5. **Validation**: Lambda function performs synthetic test establishing mTLS connection using new certificate
6. **Closure**: Update ticket in ServiceNow with renewal completion timestamp and new certificate expiration date

**Secret Rotation Failure Response**:
1. **Detection**: Lambda rotation function fails with exception (database connection timeout, invalid credentials)
2. **Notification**: SNS topic sends PagerDuty alert to on-call engineer with failure details
3. **Investigation**: On-call engineer reviews Lambda CloudWatch Logs for rotation function error messages
4. **Remediation**: Determine root cause (network connectivity, target system unavailable, rotation logic bug)
5. **Manual rollback**: If needed, use Secrets Manager console to restore `AWSPREVIOUS` version to `AWSCURRENT` label
6. **Re-attempt rotation**: Trigger manual rotation through Secrets Manager console after fixing underlying issue
7. **Post-incident**: Update rotation Lambda function if bug identified; document incident in runbook

**Agent Health Check Failure**:
1. **Detection**: Auto Scaling group health check fails (3 consecutive failures over 90 seconds)
2. **Automated remediation**: Auto Scaling group terminates unhealthy instance and launches replacement
3. **Investigation**: Engineer reviews CloudWatch Logs for terminated instance ID to identify failure reason
4. **Common causes**: Out of memory (agent memory leak), AWS API throttling, certificate expiration preventing outbound HTTPS
5. **Escalation**: If >50% of instances fail health checks simultaneously, escalate to platform architecture team (potential service-wide issue)

**Disaster Recovery Drill** (quarterly exercise):
1. **Pre-drill preparation**: Notify all stakeholders 7 days in advance with drill objectives and success criteria
2. **Failover execution**: Use Route 53 health checks to simulate primary region failure and trigger failover to secondary region
3. **Validation**: Verify certificate issuance from secondary region ACM Private CA and secret retrieval from replicated Secrets Manager
4. **Monitoring**: Collect metrics on failover time (target: <15 minutes), agent instance launch time, and application recovery time
5. **Failback**: Return traffic to primary region using Route 53 record updates
6. **Post-drill analysis**: Document lessons learned, update disaster recovery runbook, and track action items for improving RTO/RPO

### Performance Efficiency

:::image type="icon" source="../_images/goal.svg"::: **Design for low-latency operations with caching, right-sized resources, and performance monitoring**

| Recommendation | Benefit |
|----------------|---------|
| **Implement in-memory certificate caching with 12-hour TTL**: Cache issued certificates in agent memory to serve local applications without ACM Private CA API calls for 50% of certificate validity (24-hour certs) | Reduces certificate retrieval latency from 200ms (ACM API call) to <1ms (memory lookup); eliminates API throttling risk during high-throughput periods |
| **Use AWS PrivateLink for sub-5ms latency to AWS services**: Deploy VPC interface endpoints for ACM Private CA, Secrets Manager, and KMS in same availability zone as agent instances | Reduces network latency by 60-80% compared to public internet routing (typical 20-50ms to 5-10ms within same AZ); eliminates internet gateway/NAT gateway hops |
| **Enable KMS GenerateDataKey caching in AWS Encryption SDK**: Configure client-side data key caching with 5-minute cache TTL and 100-message reuse limit | Reduces KMS API calls by 99% for high-frequency secret encryption operations; decreases latency from 10ms (KMS API) to <1ms (cached key) |
| **Right-size EC2 instances using Compute Optimizer recommendations**: Deploy t3.micro instances with Unlimited mode for burstable CPU performance during certificate issuance bursts | Balances cost ($8/month per instance) with performance; Unlimited mode provides burst capacity >2 vCPUs during peak periods without throttling |
| **Monitor certificate issuance and secret retrieval latency with CloudWatch metrics**: Publish custom metrics for operation latency (p50, p95, p99) and set alarms for p99 >5 seconds | Enables proactive performance issue detection; identifies outliers indicating AWS service degradation or network problems before customer impact |

#### Scalability

Design for horizontal scaling and regional distribution:

**Auto Scaling Configuration**:
- Target tracking scaling policy: Maintain average CPU utilization at 50%
- Scale-out policy: Add 2 instances when CPU >70% for 2 consecutive minutes
- Scale-in policy: Remove 1 instance when CPU <30% for 10 consecutive minutes
- Minimum capacity: 2 instances per AZ (6 total across 3 AZs)
- Maximum capacity: 6 instances per AZ (18 total) for 3x peak capacity buffer

**Certificate Issuance Throughput**:
- ACM Private CA limits: 100 certificate issuance API calls per second per CA
- Agent design: Batching not supported for certificate issuance (each service requires unique certificate)
- Scaling strategy: Deploy multiple ACM Private CAs for >100 services requiring concurrent certificate issuance
- Cost impact: $400/month per additional ACM Private CA

**Secret Retrieval Throughput**:
- Secrets Manager limits: 5,000 GetSecretValue API calls per second per region
- Agent design: Implement client-side caching with 5-minute TTL reducing API calls by 99%
- Example: 1,000 agents polling every 30 seconds = 33 RPS without caching → 0.33 RPS with caching
- Scaling strategy: Increase cache TTL to 15 minutes for non-critical secrets (API keys) vs. 5 minutes for critical secrets (database passwords)

**KMS Decryption Throughput**:
- KMS limits: 5,500 Decrypt API calls per second per region (shared quota for symmetric key operations)
- Agent design: Use AWS Encryption SDK with data key caching to reduce KMS calls
- Example: 10,000 secret decryption operations per second → 100 KMS calls per second with 100-message data key reuse limit
- Quota increase: Request service quota increase to 10,000 RPS for KMS through AWS Service Quotas console (typically approved within 24-48 hours)

#### Performance optimization

Implement caching and connection pooling:

**C# Agent Caching Strategy**:

**Certificate Cache** (in-memory with LRU eviction):
```csharp
private static MemoryCache _certificateCache = new MemoryCache(new MemoryCacheOptions
{
    SizeLimit = 1000, // Maximum 1000 certificates cached
    ExpirationScanFrequency = TimeSpan.FromMinutes(5)
});

public async Task<X509Certificate2> GetCertificateAsync(string commonName)
{
    var cacheKey = $"cert:{commonName}";

    if (_certificateCache.TryGetValue(cacheKey, out X509Certificate2 cachedCert))
    {
        // Check certificate validity (not expired and valid for >2 hours)
        if (cachedCert.NotAfter > DateTime.UtcNow.AddHours(2))
        {
            return cachedCert;
        }
    }

    // Cache miss or certificate near expiration - fetch from ACM Private CA
    var newCert = await _acmPcaClient.IssueCertificateAsync(...);

    var cacheOptions = new MemoryCacheEntryOptions
    {
        Size = 1,
        AbsoluteExpiration = newCert.NotAfter.AddHours(-2) // Refresh 2 hours before expiry
    };

    _certificateCache.Set(cacheKey, newCert, cacheOptions);
    return newCert;
}
```

**Secret Cache** (in-memory with version tracking):
```csharp
private static ConcurrentDictionary<string, (string SecretValue, string VersionId, DateTime ExpiresAt)>
    _secretCache = new ConcurrentDictionary<string, (string, string, DateTime)>();

public async Task<string> GetSecretAsync(string secretArn)
{
    if (_secretCache.TryGetValue(secretArn, out var cached))
    {
        if (cached.ExpiresAt > DateTime.UtcNow)
        {
            return cached.SecretValue;
        }
    }

    var response = await _secretsManagerClient.GetSecretValueAsync(new GetSecretValueRequest
    {
        SecretId = secretArn,
        VersionStage = "AWSCURRENT"
    });

    _secretCache[secretArn] = (
        response.SecretString,
        response.VersionId,
        DateTime.UtcNow.AddMinutes(5) // 5-minute TTL
    );

    return response.SecretString;
}
```

**AWS SDK Connection Pooling**:
```csharp
// Configure AWS SDK with connection pooling and timeout settings
var config = new AmazonSecretsManagerConfig
{
    MaxConnectionsPerServer = 50, // HTTP connection pool size
    Timeout = TimeSpan.FromSeconds(10),
    MaxErrorRetry = 3,
    RetryMode = RequestRetryMode.Adaptive // Use adaptive retry with token bucket algorithm
};

var secretsManagerClient = new AmazonSecretsManagerClient(config);
```

**VPC Endpoint DNS Caching**:
- Configure C# HttpClient with custom DNS cache to reduce DNS resolution latency for VPC endpoint private DNS names
- Default Windows DNS cache TTL: 86400 seconds (24 hours)
- VPC endpoint DNS records have 60-second TTL; implement custom resolver checking cache every 5 minutes

#### Performance testing

Implement load testing for agent infrastructure:

**Load Testing Scenarios**:

**Certificate Issuance Burst** (simulating 1,000 services requesting certificates simultaneously):
```bash
# Using Apache Bench (ab) to load test agent API endpoint
ab -n 1000 -c 100 \
   -H "Authorization: Bearer <token>" \
   -p cert-request.json \
   -T application/json \
   https://agent-alb.example.com/api/certificates
```

**Expected Results**:
- P50 latency: <500ms (including ACM Private CA API call)
- P95 latency: <2 seconds
- P99 latency: <5 seconds
- Success rate: >99.9% (no HTTP 5xx errors)
- Auto Scaling triggers: Scale-out initiated at 70% CPU (adds 2 instances per AZ)

**Secret Retrieval Burst** (simulating application startup with 10,000 secret retrievals):
```bash
# Using wrk for high-performance HTTP load testing
wrk -t 10 -c 100 -d 60s \
    -H "Authorization: Bearer <token>" \
    https://agent-alb.example.com/api/secrets/arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/database-password
```

**Expected Results**:
- P50 latency: <50ms (cached secrets, no AWS API call)
- P95 latency: <200ms (cache miss, Secrets Manager API call)
- P99 latency: <500ms
- Cache hit rate: >95% (indicating effective 5-minute TTL)
- Throughput: >10,000 requests per second per agent instance

**Performance Benchmarks**:

**Certificate Issuance Latency** (target: p95 <2 seconds):
- ACM Private CA API call: 200-300ms
- TLS handshake (VPC endpoint): 50ms
- Certificate parsing and validation: 20ms
- Windows Credential Manager storage: 10ms
- Total end-to-end: 280-380ms (p95)

**Secret Retrieval Latency** (target: p95 <200ms):
- Secrets Manager API call: 100-150ms
- KMS decryption: 10-20ms
- Cache storage: 5ms
- Total end-to-end: 115-175ms (p95) for cache miss; <10ms for cache hit

**KMS Encryption Latency** (target: p95 <50ms):
- GenerateDataKey API call: 10-20ms (without caching)
- Decrypt API call: 10-20ms (without caching)
- With AWS Encryption SDK caching: <1ms (data key reused for 5 minutes)

## Deploy this scenario

### Prerequisites

- **AWS Account** with administrative access for creating IAM roles, KMS keys, and AWS service resources
- **AWS CLI** version 2.13.0 or later installed and configured with credentials: [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** version 1.5.0 or later for infrastructure-as-code deployment: [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
- **Visual Studio 2022** or later (or JetBrains Rider) with .NET 6.0 SDK for C# agent development
- **Git client** for cloning reference implementation repository
- **AWS Organizations** configured with CloudTrail organization trail for centralized audit logging (SOC 2 requirement)
- **AWS Config** enabled in all regions for configuration compliance monitoring
- **VPC** with at least 3 private subnets across 3 availability zones for high-availability deployment

**IAM Permissions Required**:
- `acm-pca:CreateCertificateAuthority`, `acm-pca:IssueCertificate`
- `secretsmanager:CreateSecret`, `secretsmanager:PutSecretValue`
- `kms:CreateKey`, `kms:CreateGrant`, `kms:Encrypt`, `kms:Decrypt`
- `ec2:CreateVpcEndpoint`, `ec2:CreateSecurityGroup`
- `iam:CreateRole`, `iam:AttachRolePolicy`
- `autoscaling:CreateAutoScalingGroup`, `elasticloadbalancing:CreateLoadBalancer`
- `cloudtrail:CreateTrail`, `config:PutConfigRule`

### Deployment options

#### Option 1: Terraform Infrastructure-as-Code (Recommended)

This reference implementation includes production-ready Terraform modules for all AWS resources.

**GitHub repository**: `https://github.com/example/aws-mtls-secrets-terraform` (fictional example)

```bash
# Clone the repository
git clone https://github.com/example/aws-mtls-secrets-terraform.git
cd aws-mtls-secrets-terraform

# Initialize Terraform backend and download providers
terraform init

# Review infrastructure plan
terraform plan -var-file=environments/production/terraform.tfvars

# Deploy infrastructure (requires confirmation)
terraform apply -var-file=environments/production/terraform.tfvars
```

#### Option 2: AWS CloudFormation

Deploy using AWS CloudFormation templates with nested stacks:

```bash
# Validate CloudFormation template
aws cloudformation validate-template \
  --template-body file://cloudformation/master-stack.yaml

# Create CloudFormation stack
aws cloudformation create-stack \
  --stack-name secrets-mgmt-prod \
  --template-body file://cloudformation/master-stack.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
  --capabilities CAPABILITY_NAMED_IAM

# Monitor stack creation progress
aws cloudformation wait stack-create-complete \
  --stack-name secrets-mgmt-prod
```

#### Option 3: AWS CLI Manual Deployment

Step-by-step manual deployment using AWS CLI (educational purposes only; use Terraform for production):

```bash
# Step 1: Create ACM Private Certificate Authority
aws acm-pca create-certificate-authority \
  --certificate-authority-configuration file://ca-config.json \
  --certificate-authority-type ROOT \
  --revocation-configuration file://revocation-config.json \
  --tags Key=Environment,Value=production

# Step 2: Create KMS key for Secrets Manager encryption
aws kms create-key \
  --description "Secrets Manager encryption key - production" \
  --key-policy file://kms-key-policy.json

# Step 3: Create Secrets Manager secret
aws secretsmanager create-secret \
  --name prod/database-password \
  --secret-string '{"username":"admin","password":"SecureP@ssw0rd!"}' \
  --kms-key-id alias/secrets-manager-production

# Step 4: Create IAM role for C# agent
aws iam create-role \
  --role-name SecretAgentRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name SecretAgentRole \
  --policy-arn arn:aws:iam::123456789012:policy/SecretAgentPolicy
```

### Deployment steps

1. **Phase 1: Core security infrastructure** (30-45 minutes)
   - Create AWS KMS customer master keys for each environment (dev, staging, production) with automatic rotation enabled
   - Deploy ACM Private Certificate Authority with 10-year root CA validity and 7-day certificate validity configuration
   - Configure IAM roles and policies for C# agent with least-privilege access to ACM Private CA, Secrets Manager, and KMS
   - Enable AWS CloudTrail organization trail with S3 bucket encryption and log file validation
   - Deploy AWS Config configuration recorder and compliance rules (KMS encryption required, IMDSv2 enforced)

2. **Phase 2: Network and connectivity** (20-30 minutes)
   - Create VPC interface endpoints for ACM Private CA, Secrets Manager, KMS, and CloudWatch Logs in agent VPC
   - Configure security groups allowing HTTPS (443) from agent instances to VPC endpoints
   - Enable VPC endpoint private DNS names for transparent AWS SDK integration
   - Create S3 gateway endpoint for CRL downloads and CloudTrail log delivery
   - Validate VPC endpoint connectivity using EC2 instance in private subnet with `nslookup secretsmanager.us-east-1.amazonaws.com`

3. **Phase 3: Secrets management and rotation** (15-20 minutes)
   - Create Secrets Manager secrets for production workloads (database credentials, API keys) with KMS encryption
   - Deploy Lambda rotation functions for RDS MySQL, PostgreSQL, and generic API key rotation
   - Configure rotation schedules (30 days for database credentials, 90 days for API keys)
   - Grant Lambda execution role permissions for Secrets Manager PutSecretValue and target system credential updates
   - Test rotation manually using `aws secretsmanager rotate-secret` to validate Lambda function logic

4. **Phase 4: C# agent deployment** (30-45 minutes)
   - Build C# agent application using .NET 6.0 SDK with AWS SDK dependencies
   - Create custom AMI from Windows Server 2019 base image with agent service installed
   - Configure EC2 launch template with agent AMI, IAM instance profile (SecretAgentRole), IMDSv2 enabled, and user data script installing AWS Systems Manager Agent
   - Create Application Load Balancer with HTTPS listener and target group with `/health` health check endpoint
   - Deploy Auto Scaling group (minimum 6 instances across 3 AZs) with launch template and target tracking scaling policy (50% CPU utilization)
   - Validate agent functionality by calling API endpoint: `curl https://agent-alb.example.com/api/health`

5. **Phase 5: Monitoring and compliance** (20-30 minutes)
   - Create CloudWatch Logs log groups for agent application logs, Lambda rotation logs, and VPC flow logs
   - Deploy CloudWatch dashboards for certificate management, secrets management, and agent health
   - Configure CloudWatch alarms for certificate expiration (<30 days), secret rotation failures, and agent health check failures
   - Create EventBridge rules for certificate expiration events, secret rotation events, and KMS key deletion attempts
   - Enable AWS GuardDuty for intelligent threat detection analyzing CloudTrail logs and VPC flow logs
   - Configure AWS Security Hub for aggregated compliance findings and SOC 2 controls mapping

### Post-deployment configuration

- **Issue test certificates**: Use agent API to request test certificate from ACM Private CA and validate certificate chain against root CA
  ```bash
  curl -X POST https://agent-alb.example.com/api/certificates \
    -H "Content-Type: application/json" \
    -d '{"commonName":"test-service.internal.example.com","validityDays":7}'
  ```

- **Configure certificate auto-renewal**: Set up EventBridge scheduled rule triggering Lambda function 7 days before certificate expiration to notify certificate owners
  ```bash
  aws events put-rule \
    --name certificate-expiration-reminder \
    --schedule-expression "rate(1 day)" \
    --state ENABLED
  ```

- **Test secret rotation**: Trigger manual secret rotation for test secret and validate new credentials work with target system (database, API)
  ```bash
  aws secretsmanager rotate-secret \
    --secret-id test/database-password \
    --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:mysql-rotation
  ```

- **Configure backup and disaster recovery**: Enable Secrets Manager cross-region replication to secondary region (us-west-2) for critical production secrets
  ```bash
  aws secretsmanager replicate-secret-to-regions \
    --secret-id prod/database-password \
    --add-replica-regions Region=us-west-2,KmsKeyId=arn:aws:kms:us-west-2:123456789012:key/replica-key
  ```

- **Enable SOC 2 compliance monitoring**: Configure AWS Audit Manager assessment using pre-built SOC 2 framework template
  ```bash
  aws auditmanager create-assessment \
    --name "Secrets Management SOC 2 Assessment" \
    --assessment-reports-destination DestinationType=S3,Destination=s3://audit-reports-bucket \
    --framework-id <SOC-2-FRAMEWORK-ID>
  ```

### Validation

To validate the deployment:

1. **Verify ACM Private CA is active and issuing certificates**:
   ```bash
   aws acm-pca describe-certificate-authority \
     --certificate-authority-arn <CA-ARN> \
     --query 'CertificateAuthority.Status' \
     --output text
   # Expected output: ACTIVE
   ```

2. **Test certificate issuance through agent API**:
   ```bash
   curl -X POST https://agent-alb.example.com/api/certificates \
     -H "Authorization: Bearer $(aws sts get-session-token --query Credentials.SessionToken --output text)" \
     -H "Content-Type: application/json" \
     -d '{"commonName":"validation-test.internal.example.com","validityDays":7}' \
     -o test-certificate.pem

   # Validate certificate chain
   openssl verify -CAfile root-ca.pem -untrusted intermediate-ca.pem test-certificate.pem
   # Expected output: test-certificate.pem: OK
   ```

3. **Verify secret retrieval through agent API**:
   ```bash
   curl https://agent-alb.example.com/api/secrets/prod/database-password \
     -H "Authorization: Bearer $(aws sts get-session-token --query Credentials.SessionToken --output text)"
   # Expected output: {"username":"admin","password":"SecureP@ssw0rd!","host":"database.internal.example.com"}
   ```

4. **Validate Windows Credential Manager integration** (on Windows agent host):
   ```powershell
   # List stored credentials
   cmdkey /list | Select-String "prod/database-password"

   # Retrieve credential using PowerShell
   $cred = (Get-StoredCredential -Target "prod/database-password")
   $cred.UserName  # Expected: admin
   $cred.GetNetworkCredential().Password  # Expected: SecureP@ssw0rd!
   ```

5. **Confirm CloudTrail audit logging is capturing events**:
   ```bash
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=EventName,AttributeValue=IssueCertificate \
     --max-results 10 \
     --query 'Events[*].[EventTime,Username,EventName,CloudTrailEvent]' \
     --output table
   ```

6. **Verify secret rotation functionality**:
   ```bash
   # Trigger rotation
   aws secretsmanager rotate-secret \
     --secret-id test/api-key \
     --rotation-lambda-arn <LAMBDA-ARN>

   # Check rotation status
   aws secretsmanager describe-secret \
     --secret-id test/api-key \
     --query 'RotationEnabled' \
     --output text
   # Expected output: True
   ```

7. **Test disaster recovery failover** (optional, requires secondary region deployment):
   ```bash
   # Simulate primary region failure by updating Route 53 health check
   aws route53 update-health-check \
     --health-check-id <PRIMARY-HEALTH-CHECK-ID> \
     --disabled

   # Verify DNS resolves to secondary region endpoint
   nslookup agent-alb.example.com
   # Expected: IP address in us-west-2 CIDR range
   ```

## Contributors

*This document applies Azure Well-Architected Framework principles to AWS service architecture.*

**Principal authors:**
- Platform Engineering Team | Cloud Security Architect
- DevOps Team | Site Reliability Engineer

**Other contributors:**
- Security Operations Team | SOC 2 Compliance Specialist
- Infrastructure Team | AWS Solutions Architect

## Next steps

### Product documentation

- [AWS Certificate Manager Private CA documentation](https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaWelcome.html)
- [AWS Secrets Manager documentation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [AWS Key Management Service documentation](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
- [AWS PrivateLink (VPC Endpoints) documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
- [AWS CloudTrail documentation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html)
- [AWS Identity and Access Management documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)

### Architecture guidance

- [AWS Security Best Practices whitepaper](https://docs.aws.amazon.com/security/)
- [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [SOC 2 Compliance on AWS](https://aws.amazon.com/compliance/soc-2-faqs/)
- [mTLS Authentication Best Practices](https://aws.amazon.com/blogs/security/how-to-use-aws-certificate-manager-private-certificate-authority-for-mutual-tls/)

### Well-Architected Framework

- **Azure Well-Architected Framework** (principles applied to this AWS architecture): https://learn.microsoft.com/azure/well-architected/
- **Reliability pillar**: https://learn.microsoft.com/azure/well-architected/reliability/
- **Security pillar**: https://learn.microsoft.com/azure/well-architected/security/
- **Cost Optimization pillar**: https://learn.microsoft.com/azure/well-architected/cost-optimization/
- **Operational Excellence pillar**: https://learn.microsoft.com/azure/well-architected/operational-excellence/
- **Performance Efficiency pillar**: https://learn.microsoft.com/azure/well-architected/performance-efficiency/

### Reference implementations

- **AWS Samples - Secrets Manager Rotation Examples**: https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas
- **AWS Samples - ACM Private CA Examples**: https://github.com/aws-samples/aws-certificate-manager-private-certificate-authority-workshop
- **Terraform AWS Modules**: https://registry.terraform.io/modules/terraform-aws-modules/

## Related resources

### Related architectures

- **AWS Certificate Manager Private CA Workshop**: Step-by-step guide for deploying private PKI infrastructure on AWS with certificate issuance workflows
- **AWS Secrets Manager Rotation Patterns**: Reference architectures for automatic credential rotation in RDS, Redshift, DocumentDB, and custom applications
- **Zero-Trust Architecture on AWS**: Comprehensive guide for implementing zero-trust network security with mTLS, identity-based access, and microsegmentation

### Related guidance

- **PKI Best Practices**: Industry standards for certificate authority operations, key escrow, certificate revocation, and certificate lifecycle management
- **Secret Zero Problem**: Patterns for bootstrapping initial credentials in distributed systems including AWS EC2 instance metadata, AWS Systems Manager Parameter Store, and HashiCorp Vault AWS auth method
- **FIPS 140-2 Compliance on AWS**: Guide for configuring AWS KMS in FIPS mode, using CloudHSM for FIPS Level 3 certification, and enabling FIPS endpoints for AWS services

### Case studies

- **Financial Services Company**: Implemented ACM Private CA for internal microservices mTLS authentication supporting 50,000 certificates across 500 services with 7-day certificate validity
- **Healthcare Provider**: Deployed Secrets Manager with automatic rotation for HIPAA-compliant database credential management across 100+ RDS instances with zero-downtime rotation
- **E-commerce Platform**: Used KMS envelope encryption for PCI DSS compliance protecting cardholder data at rest with quarterly key rotation and comprehensive CloudTrail audit logs

### SOC 2 Compliance Mapping

This architecture implements the following SOC 2 Trust Service Criteria:

| SOC 2 Criterion | Control Implementation | Evidence |
|-----------------|------------------------|----------|
| CC6.1 - Logical and Physical Access Controls | IAM roles with least-privilege policies, MFA enforcement, VPC endpoints for private network access | CloudTrail logs showing IAM policy evaluations, AWS Config rules validating IMDSv2 and MFA enforcement |
| CC6.6 - Encryption of Data at Rest | KMS customer-managed keys for Secrets Manager encryption, Windows Credential Manager DPAPI encryption, S3 SSE-KMS for audit logs | AWS Config rules detecting unencrypted secrets, KMS key policies requiring encryption context |
| CC6.7 - Encryption of Data in Transit | TLS 1.3 for AWS API communication, mTLS for service-to-service authentication, VPC PrivateLink eliminating public internet exposure | VPC Flow Logs showing encrypted traffic, certificate validation logs from ACM Private CA |
| CC7.2 - Detection of Security Events | CloudTrail audit logging with immutable S3 storage, GuardDuty threat detection, CloudWatch alarms for anomalous behavior | CloudTrail log file validation hashes, GuardDuty findings for IAM credential exfiltration, CloudWatch alarm history |
| CC8.1 - Change Management | Infrastructure-as-code (Terraform) with version control, blue/green deployments with rollback capability, Config change tracking | Git commit history for infrastructure changes, Auto Scaling instance refresh logs, Config timeline showing resource configuration changes |
