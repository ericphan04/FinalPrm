param(
  [string[]]$ProjectIds = @("shoestoremarketplace", "demo-no-project"),
  [string]$HostPort = "127.0.0.1:8090"
)

$ErrorActionPreference = "Stop"

foreach ($projectId in $ProjectIds) {
  $base = "http://$HostPort/v1/projects/$projectId/databases/(default)/documents/products"
  Write-Host "Checking products for project: $projectId"

  try {
    $response = Invoke-RestMethod -Uri $base -Method Get
  } catch {
    Write-Host "  Cannot reach Firestore emulator at $HostPort for $projectId"
    continue
  }

  if (-not $response.documents) {
    Write-Host "  No products found."
    continue
  }

  foreach ($doc in $response.documents) {
    $docUrl = "http://$HostPort/v1/$($doc.name)"
    Invoke-RestMethod -Uri $docUrl -Method Delete | Out-Null
    Write-Host "  Deleted $($doc.name.Split('/')[-1])"
  }
}

Write-Host "Done."
