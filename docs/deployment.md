# Reproduce and validate a cloud deployment

Deployment is optional and unverified. Do not run apply until the account owner approves
the billable resources. Read the cost and cleanup guide first. Use a dedicated sandbox.

## Before deployment

Install Terraform and Azure CLI from their official distributions. Authenticate with
`az login`, select the intended subscription with `az account set --subscription YOUR_ID`,
and verify `az account show`. Never store tokens or client secrets in tfvars. For CI,
prefer federation instead of long-lived service-principal secrets; CI here only validates.

An authorized administrator must register Microsoft.Network, Microsoft.Storage,
Microsoft.KeyVault, Microsoft.OperationalInsights, Microsoft.ManagedIdentity, and
Microsoft.Insights if not already registered. Registration is intentionally not automated.
The deployer requires resource-creation rights plus scoped role-assignment rights and
subscription diagnostic-setting rights. Respect existing policies and diagnostics limits.

Copy `terraform.tfvars.example` to `terraform.tfvars`, replace subscription and tenant
UUIDs, and choose a globally unique suffix. The UUID values are identifiers, not secrets;
the example zero values cannot deploy a meaningful environment. Confirm the chosen
region and names. Then:

```sh
terraform init
terraform fmt -check -recursive
terraform validate
terraform test
terraform plan -out=lab.tfplan
```

Review the plan for only the named lab resources, exact RBAC scopes, network settings,
and the subscription diagnostic setting. Only after cost approval:

```sh
terraform apply lab.tfplan
terraform output
```

Local state is used for a single-person lab. It can contain sensitive metadata even
without secret resources. Protect its directory and backups with local access controls
and disk encryption. For shared use, first configure a separately provisioned Azure
Storage backend with Entra authentication, restricted access, encryption, and locking;
do not put backend credentials in source control. `.gitignore` excludes plans and state.

## Secret lifecycle and runtime verification

No compute or secret value is deployed. Use an independently approved private client
in the client subnet (or connected network), with a separately authorized secret writer
scoped to this vault. Do not attach a new public IP or enable public service access to
work around private DNS. Initialize synthetic secret/blob data outside Terraform;
never put real secret values in a shell history, a screenshot, or this repository.

Attach the generated managed identity to the authorized client workload. From that
client, verify DNS resolves the storage/vault service names to private endpoint IPs,
then obtain a managed-identity session (`az login --identity --client-id ID`).
Use `az storage blob list --account-name NAME --container-name LAB_CONTAINER --auth-mode login`
and `az keyvault secret show --vault-name NAME --name LAB_SECRET --query id -o tsv`.
Record status only, never the secret value. Successful secret access should be followed
by a denied write attempt against disposable synthetic data. A public-network request
must fail. A client outside the permitted subnet must fail endpoint access.

Finally generate synthetic read activity and verify AuditEvent/blob activity in the
workspace, plus subscription administrative events in AzureActivity. Allow for ingestion
delay and inspect destination mode/table names in the actual workspace; do not assume
logs exist just because diagnostic settings were accepted. The 1 GB/day workspace quota
can interrupt collection and is not a reliable total cost limit.

## Acceptance record

| Check | Current status |
| --- | --- |
| Terraform formatting/schema | Passed locally |
| Mocked security and invalid-input tests | Passed locally |
| Real plan and apply | Not performed |
| Private DNS and denied public data access | Not performed |
| Workload read allowed, write denied | Not performed |
| Audit records arrive in workspace | Not performed |
| Destroy and recoverable-vault behavior | Not performed |

Record real test dates, commands, sanitized results, and any policy differences only
after running them. A mocked test pass is not a cloud integration pass.
