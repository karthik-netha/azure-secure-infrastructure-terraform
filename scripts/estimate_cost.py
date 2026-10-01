"""Transparent monthly estimate; assumptions, not a billing forecast."""
import json
from pathlib import Path
c=json.loads(Path('costs.example.json').read_text())
pe=c['hours']*c['private_endpoints']*c['private_endpoint_hourly_assumption']
logs=30*c['log_gb_per_day']*c['log_gb_rate_assumption']
print(json.dumps({'currency':c['currency'],'private_endpoints':round(pe,2),'log_ingestion':round(logs,2),'other_allowance':c['storage_dns_vault_allowance'],'illustrative_monthly_total':round(pe+logs+c['storage_dns_vault_allowance'],2),'not_a_quote':True},indent=2))
