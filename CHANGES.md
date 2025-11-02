# Azure Support Changes

## What's Changed

### Code Cleanup
- Removed `validate_azure.exs` (temp validation script)
- Fixed double `when` guard in cloudnative_pg_clusters.ex
- Removed empty init() in azure.go
- Changed `cond` to `case` in battery_core.ex (better pattern matching)

### Azure Karpenter Updates
- Updated to new embedded schema pattern
- Added to SystemBattery and RootResourceGenerator
- Made instance types configurable
- Fixed API version mappings (removed duplicate node_pool)

### Azure Load Balancer Controller
- Using app_labels method now
- Extracted deployment spec to variable
- Added workload identity annotations

### CloudNativePG Backup
- Added require_valid_backup_config function
- Supports both AWS S3 and Azure Blob Storage
- Uses workload identity for Azure

### Storage Classes
- `managed-premium` as default (better perf)
- All standard Azure disk types included
- Using disk.csi.azure.com driver

## Notes

**Autoscaler vs Karpenter**: Don't use both together
- Cluster Autoscaler: traditional, stable
- Karpenter: newer, smarter scaling (recommended for new stuff)
