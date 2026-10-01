# Cost model and cleanup

`costs.example.json` exposes every assumption used by `scripts/estimate_cost.py`.
For a 730-hour month: endpoints = 2 × 730 × $0.01 = $14.60; logs = 30 × 0.1 GB ×
$3 = $9; illustrative storage/DNS/vault allowance = $5; total = $28.60 USD.
The rates are assumptions, not verified regional quotes. At 1 GB/day the same log
assumption becomes $90 and the illustrative total $109.60. At $0.01/endpoint-hour,
two endpoints alone would be $0.48 for 24 hours.

Reprice Private Link, Azure Monitor ingestion/retention, Storage capacity/transactions,
Key Vault operations, and Private DNS in the Azure calculator for the actual subscription.
Private Link data processing, egress, tax, longer retention, monitoring changes, and any
added VM/VPN/Sentinel are excluded. A budget alert informs; it does not enforce a cap.
The workspace ingestion quota does not cover other services and can create monitoring gaps.

## Cleanup sequence

1. Save only synthetic, sanitized evidence needed for learning. Confirm ownership of all
   resources and that no other workload depends on the subscription diagnostic setting.
2. Run `terraform plan -destroy -out=destroy.tfplan` and review every deletion.
3. Run `terraform apply destroy.tfplan` only for the reviewed lab cleanup. This deletes
   the lab's subscription diagnostic setting as well as its resource-group resources.
4. Confirm resources and diagnostic settings are gone in Azure. Check Cost Management
   again after billing data catches up. Do not interpret a successful CLI message as a
   finalized invoice.
5. Key Vault purge protection is intentional. Soft-deleted vault names remain reserved
   during retention (7 days configured). Use a new suffix or an authorized recovery;
   do not disable purge protection to speed up a demo.
6. Retain state securely until cleanup is verified. Then remove only this lab's local
   plans/state/backups and `.terraform` directory if no longer needed. Keep the lockfile.

Neither deployment nor destroy has been run for this portfolio build.
