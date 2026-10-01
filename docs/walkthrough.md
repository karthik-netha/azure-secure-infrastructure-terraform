# Demo and interview guide

Start with the diagram and explain that the workload is a future integration. Run init,
fmt, validate and test. Show the public-access, identity, NSG, and logging assertions.
Trace the managed identity into the two resource-scoped role assignments. Then run
the cost script and show how higher ingestion changes the estimate. Finish with the
cloud acceptance checklist and purge-protection cleanup caveat.

**Does a private endpoint alone secure a service?** No. This code also disables public
data access, sets deny network ACLs, links DNS, enables endpoint network policies,
and limits inbound TLS through an NSG. Runtime reachability still needs testing.

**Why two kinds of permission?** Terraform's deployer creates resources and role
assignments. The workload identity only reads blob data and vault secrets at the two
resource scopes. Control-plane Reader alone does not grant those data permissions.

**Where are the secrets?** None are in this code or initialized by Terraform. The vault
is the storage mechanism; a separately authorized writer and private client initialize
synthetic values after deployment. This avoids secret values in Terraform state.

**Why platform-managed encryption rather than CMK?** It provides encryption without a
key rotation and dependency lifecycle the lab has not implemented. Infrastructure
encryption is enabled, but customer-managed key ownership is not claimed.

**What do mocked tests prove?** The provider schema accepts the configuration and the
planned attributes satisfy assertions. They do not exercise Azure authorization, name
availability, policies, packet flow, DNS, or log delivery.

**What would you add for production?** Workload-specific/container-specific RBAC,
private authenticated remote state, policy controls, workload egress restrictions,
resilient log-health monitoring, identity federation, and tested recovery procedures.
These are next steps, not capabilities already demonstrated here.
