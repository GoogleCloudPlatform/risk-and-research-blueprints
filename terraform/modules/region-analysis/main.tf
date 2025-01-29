locals {
  # Map regions to their multi-region parent
  region_mapping = {
    for region in var.regions : region => (
      can(regex("^us-", region)) ? "us" :
      can(regex("^europe-", region)) ? "europe" :
      can(regex("^asia-", region)) ? "asia" : "unknown"
    )
  }

  # Count occurrences of each multi-region
  region_counts = {
    us     = length([for region, multi in local.region_mapping : region if multi == "us"])
    europe = length([for region, multi in local.region_mapping : region if multi == "europe"])
    asia   = length([for region, multi in local.region_mapping : region if multi == "asia"])
  }

  # Find the maximum count
  max_count = max(values(local.region_counts)...)

  # Create a map of multi-regions at max count
  max_count_regions = {
    for name, count in local.region_counts : name => count
    if count == local.max_count
  }

  # Determine dominant region with US preference
  dominant_region = contains(keys(local.max_count_regions), "us") ? "us" : (
    length(keys(local.max_count_regions)) > 0 ? sort(keys(local.max_count_regions))[0] : "us"
  )

  # Get all regions from the dominant multi-region
  regions_in_dominant = [
    for region, multi in local.region_mapping : region
    if multi == local.dominant_region
  ]

  # Sort all input regions to ensure deterministic selection for fallback
  sorted_input_regions = sort(var.regions)

  # Select the alphabetically first region from the dominant multi-region
  # If no regions in dominant, fall back to first region from input list
  default_region = length(local.regions_in_dominant) > 0 ? sort(local.regions_in_dominant)[0] : local.sorted_input_regions[0]
}