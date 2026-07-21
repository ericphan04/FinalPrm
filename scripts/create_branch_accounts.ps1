param(
  [string]$ApiKey = "AIzaSyCiAWCWokDMAKDOeI1fKBanXSBju13RjMs",
  [string]$ProjectId = "shoestoremarketplace"
)

$ErrorActionPreference = "Stop"

$branches = @(
  @{
    email = "branch.haichau@shoestoremarketplace.com"
    password = "Branch@123456"
    displayName = "Chi nhanh Hai Chau"
    storeName = "Chi nhanh Hai Chau - Da Nang"
    slug = "chi-nhanh-hai-chau-da-nang"
    address = "Hai Chau, Da Nang"
    phone = "0905000001"
    description = "Company branch in Hai Chau, Da Nang."
  },
  @{
    email = "branch.dienban@shoestoremarketplace.com"
    password = "Branch@123456"
    displayName = "Chi nhanh Dien Ban"
    storeName = "Chi nhanh Dien Ban - Da Nang"
    slug = "chi-nhanh-dien-ban-da-nang"
    address = "Dien Ban, Da Nang"
    phone = "0905000002"
    description = "Company branch in Dien Ban, Da Nang."
  }
)

function New-StringField($value) {
  return @{ stringValue = [string]$value }
}

function New-TimestampFieldNow {
  return @{ timestampValue = (Get-Date).ToUniversalTime().ToString("o") }
}

function Invoke-IdentitySignup($branch) {
  $signupUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$ApiKey"
  $signinUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey"
  $body = @{
    email = $branch.email
    password = $branch.password
    returnSecureToken = $true
  } | ConvertTo-Json

  try {
    return Invoke-RestMethod -Uri $signupUrl -Method Post -ContentType "application/json" -Body $body
  } catch {
    $message = $_.ErrorDetails.Message
    if (-not $message -and $_.Exception.Response) {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $message = $reader.ReadToEnd()
    }
    if ($message -like "*EMAIL_EXISTS*") {
      return Invoke-RestMethod -Uri $signinUrl -Method Post -ContentType "application/json" -Body $body
    }
    throw
  }
}

function Set-AuthDisplayName($idToken, $displayName) {
  $updateUrl = "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$ApiKey"
  $body = @{
    idToken = $idToken
    displayName = $displayName
    returnSecureToken = $true
  } | ConvertTo-Json
  return Invoke-RestMethod -Uri $updateUrl -Method Post -ContentType "application/json" -Body $body
}

function Set-FirestoreDoc($path, $fields, $idToken, $updateMaskFields = @()) {
  $url = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$path"
  if ($updateMaskFields.Count -gt 0) {
    $query = ($updateMaskFields | ForEach-Object { "updateMask.fieldPaths=$_" }) -join "&"
    $url = "$url`?$query"
  }
  $headers = @{ Authorization = "Bearer $idToken" }
  $body = @{ fields = $fields } | ConvertTo-Json -Depth 10
  Invoke-RestMethod -Uri $url -Method Patch -ContentType "application/json" -Headers $headers -Body $body | Out-Null
}

function Test-FirestoreDocExists($path, $idToken) {
  $url = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$path"
  $headers = @{ Authorization = "Bearer $idToken" }
  try {
    Invoke-RestMethod -Uri $url -Method Get -Headers $headers | Out-Null
    return $true
  } catch {
    return $false
  }
}

foreach ($branch in $branches) {
  $auth = Invoke-IdentitySignup $branch
  $auth = Set-AuthDisplayName $auth.idToken $branch.displayName
  $uid = $auth.localId
  $idToken = $auth.idToken

  $userFields = @{
    displayName = New-StringField $branch.displayName
    email = New-StringField $branch.email
    avatarUrl = New-StringField ""
    photoUrl = New-StringField ""
    phone = New-StringField $branch.phone
    address = New-StringField $branch.address
    role = New-StringField "seller"
    roleMirror = New-StringField "seller"
    status = New-StringField "active"
    createdAt = New-TimestampFieldNow
    updatedAt = New-TimestampFieldNow
  }

  $storeFields = @{
    ownerUid = New-StringField $uid
    name = New-StringField $branch.storeName
    slug = New-StringField $branch.slug
    phone = New-StringField $branch.phone
    address = New-StringField $branch.address
    description = New-StringField $branch.description
    logoUrl = New-StringField ""
    status = New-StringField "active"
    createdAt = New-TimestampFieldNow
    updatedAt = New-TimestampFieldNow
  }

  if (Test-FirestoreDocExists "users/$uid" $idToken) {
    $profileFields = @{
      displayName = New-StringField $branch.displayName
      email = New-StringField $branch.email
      avatarUrl = New-StringField ""
      photoUrl = New-StringField ""
      phone = New-StringField $branch.phone
      address = New-StringField $branch.address
      updatedAt = New-TimestampFieldNow
    }
    Set-FirestoreDoc "users/$uid" $profileFields $idToken @("displayName", "email", "avatarUrl", "photoUrl", "phone", "address", "updatedAt")
  } else {
    Set-FirestoreDoc "users/$uid" $userFields $idToken
  }
  Set-FirestoreDoc "stores/$uid" $storeFields $idToken

  Write-Host "Created/updated branch: $($branch.email) uid=$uid"
}
