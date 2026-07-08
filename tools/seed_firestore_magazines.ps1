param(
  [string]$SeedPath = "$PSScriptRoot\firestore_magazine_seed.json",
  [string]$ServiceAccountPath = "$PSScriptRoot\serviceAccountKey.json",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function ConvertTo-Base64Url([byte[]]$Bytes) {
  return [Convert]::ToBase64String($Bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

function Get-AccessToken($ServiceAccount) {
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $header = @{ alg = "RS256"; typ = "JWT" } | ConvertTo-Json -Compress
  $claim = @{
    iss = $ServiceAccount.client_email
    scope = "https://www.googleapis.com/auth/datastore"
    aud = "https://oauth2.googleapis.com/token"
    iat = $now
    exp = $now + 3600
  } | ConvertTo-Json -Compress

  $unsigned = "$(ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($header))).$(ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($claim)))"
  $rsa = [System.Security.Cryptography.RSA]::Create()
  $rsa.ImportFromPem($ServiceAccount.private_key)
  $signature = $rsa.SignData(
    [Text.Encoding]::UTF8.GetBytes($unsigned),
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
  )
  $jwt = "$unsigned.$(ConvertTo-Base64Url $signature)"

  $tokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "https://oauth2.googleapis.com/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
      grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
      assertion = $jwt
    }
  return $tokenResponse.access_token
}

function ConvertTo-FirestoreValue($Value) {
  if ($null -eq $Value) {
    return @{ nullValue = $null }
  }
  if ($Value -is [array]) {
    return @{
      arrayValue = @{
        values = @($Value | ForEach-Object { ConvertTo-FirestoreValue $_ })
      }
    }
  }
  if ($Value -is [string]) {
    return @{ stringValue = $Value }
  }
  if ($Value -is [bool]) {
    return @{ booleanValue = $Value }
  }
  if ($Value -is [int] -or $Value -is [long]) {
    return @{ integerValue = "$Value" }
  }
  if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) {
    return @{ doubleValue = [double]$Value }
  }
  if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string] -and $Value -isnot [pscustomobject]) {
    return @{
      arrayValue = @{
        values = @($Value | ForEach-Object { ConvertTo-FirestoreValue $_ })
      }
    }
  }
  if ($Value -is [pscustomobject] -or $Value -is [hashtable]) {
    $fields = @{}
    foreach ($property in $Value.PSObject.Properties) {
      $fields[$property.Name] = ConvertTo-FirestoreValue $property.Value
    }
    return @{ mapValue = @{ fields = $fields } }
  }
  return @{ stringValue = [string]$Value }
}

function ConvertTo-FirestoreDocument($Object) {
  $fields = @{}
  foreach ($property in $Object.PSObject.Properties) {
    if ($property.Name -eq "id" -or $property.Name -eq "articles") {
      continue
    }
    if ($property.Name -eq "paragraphs") {
      $paragraphs = @(
        foreach ($segments in @($property.Value)) {
          [pscustomobject]@{ segments = @($segments) }
        }
      )
      $fields[$property.Name] = ConvertTo-FirestoreValue $paragraphs
      continue
    }
    $fields[$property.Name] = ConvertTo-FirestoreValue $property.Value
  }
  $fields["updatedAt"] = @{ timestampValue = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") }
  return @{ fields = $fields }
}

function Save-FirestoreDocument($ProjectId, $Path, $Body, $Token) {
  $encodedSegments = ($Path -split "/" | ForEach-Object { [Uri]::EscapeDataString($_) }) -join "/"
  $uri = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$encodedSegments"
  $json = $Body | ConvertTo-Json -Depth 40 -Compress
  if ($DryRun) {
    Write-Host "[dry-run] PATCH $Path"
    return
  }
  Invoke-RestMethod `
    -Method Patch `
    -Uri $uri `
    -Headers @{ Authorization = "Bearer $Token" } `
    -ContentType "application/json; charset=utf-8" `
    -Body $json | Out-Null
}

if (!(Test-Path $SeedPath)) {
  throw "Seed file not found: $SeedPath"
}
if (!$DryRun -and !(Test-Path $ServiceAccountPath)) {
  throw "Service account JSON not found: $ServiceAccountPath`nDownload it from Firebase Console > Project settings > Service accounts, then save it here or pass -ServiceAccountPath."
}

$seed = Get-Content $SeedPath -Raw | ConvertFrom-Json
$serviceAccount = if (Test-Path $ServiceAccountPath) {
  Get-Content $ServiceAccountPath -Raw | ConvertFrom-Json
} else {
  $null
}
$projectId = if ($seed.projectId) { $seed.projectId } else { $serviceAccount.project_id }
$token = if ($DryRun) { "" } else { Get-AccessToken $serviceAccount }

$count = 0
$articleCount = 0
foreach ($magazine in $seed.magazines) {
  $magazineId = $magazine.id
  Save-FirestoreDocument $projectId "magazines/$magazineId" (ConvertTo-FirestoreDocument $magazine) $token
  $count++

  foreach ($article in @($magazine.articles)) {
    $articleId = $article.id
    Save-FirestoreDocument $projectId "magazines/$magazineId/articles/$articleId" (ConvertTo-FirestoreDocument $article) $token
    $articleCount++
  }
}

Write-Host "Seed complete: $count magazines, $articleCount articles -> project $projectId"
