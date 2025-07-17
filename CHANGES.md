# Azure Support Implementation Changes

## Summary

This document outlines the changes made to address PR #2323 comments for Azure
support implementation.

## Changes Made

### 1. Removed Temporary Files

- **Deleted `validate_azure.exs`** - Removed temporary validation script as
  requested by @elliottneilclark

### 2. Code Style Improvements

- **Changed `cond` to `case`** in
  `platform_umbrella/apps/common_core/lib/common_core/resources/bootstrap/battery_core.ex` -
  Following @JTarasovic's suggestion for better pattern matching
- **Changed `cond` to `if`** in
  `platform_umbrella/apps/common_core/lib/common_core/resources/postgres/cloudnative_pg_clusters.ex` -
  Simplified conditional logic for backup configuration

### 3. Fixed Syntax Errors

- **Fixed double `when` guard** in `cloudnative_pg_clusters.ex` - Combined
  multiple when clauses into a single guard expression
- **Removed empty `init()` function** in `bi/cmd/azure/azure.go` - Cleaned up
  unnecessary empty function

### 4. Updated Azure Command Registration

- **Refactored Azure command** in `bi/cmd/azure/azure.go` - Updated to follow
  the same pattern as AWS command with proper registration
- **Added Azure import** in `bi/main.go` - Ensured Azure command is properly
  imported and registered

### 5. Updated Azure Karpenter Configuration

- **Modernized AzureKarpenterConfig** - Updated from old battery pattern to new
  embedded schema pattern matching other Azure configs
- **Added Azure Karpenter to SystemBattery** - Added missing alias and type
  mapping
- **Added Azure Karpenter to RootResourceGenerator** - Added missing alias and
  generator mapping

### 6. Additional PR Comments Addressed

- **Updated API version mappings** - Removed duplicate node_pool entry and kept only the correct Karpenter API versions
- **Added defaultable_field usage** - Updated Azure cluster autoscaler config to use defaultable_field for configuration options
- **Added instance types configuration** - Made Azure instance types configurable via defaultable_field in AzureKarpenterConfig
- **Fixed label usage** - Updated Azure Load Balancer Controller to use app_labels method instead of manual labels
- **Extracted deployment spec** - Made deployment spec a variable for better readability in Azure Load Balancer Controller
- **Added backup validation function** - Created require_valid_backup_config function for cleaner backup configuration validation
- **Added clarifying comments** - Explained the difference between Azure Cluster Autoscaler and Karpenter in image_registry.yaml

## Justifications for Existing Code

### Azure Load Balancer Controller Implementation

The implementation follows Kubernetes best practices:

- Uses workload identity for secure authentication
- Implements proper RBAC with minimal required permissions
- Follows the official Azure documentation for AKS integration

### Storage Class Implementation

The AKS storage classes match Azure's recommended configurations:

- `managed-premium` as default for better performance
- Includes all standard Azure disk types (Standard LRS, Premium LRS, Standard
  SSD)
- Uses proper CSI driver (`disk.csi.azure.com`)

### Backup Configuration

The CloudNativePG backup configuration properly supports both AWS S3 and Azure
Blob Storage:

- Uses workload identity for Azure (`inheritFromAzureAD: true`)
- Correctly formats Azure blob storage paths
- Maintains backward compatibility with AWS S3 backups

### Azure Autoscaler vs Karpenter

Both Azure Cluster Autoscaler and Azure Karpenter are included but should not be used together:

- **Azure Cluster Autoscaler**: Traditional autoscaling solution, stable and well-tested
- **Azure Karpenter**: Newer, more intelligent node provisioning with better scaling decisions
- Users should choose one based on their needs - Karpenter is recommended for new deployments
