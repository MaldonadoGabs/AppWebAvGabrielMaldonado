# Diagnostic gather for PoliMusic IIS deployment (temporary file)
$out = "C:\Users\gabri\source\repos\AppWebAvGabrielMaldonado\webapppolimusicv1_asp\_tests\_diag.txt"
"=== OS / IIS version ===" | Out-File $out -Encoding utf8
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp" -ErrorAction SilentlyContinue) | Select-Object SetupString, MajorVersion, MinorVersion | Format-List | Out-File $out -Append -Encoding utf8

"=== IIS-ASP feature ===" | Out-File $out -Append -Encoding utf8
Get-WindowsOptionalFeature -Online -FeatureName IIS-ASP -ErrorAction SilentlyContinue |
  Select-Object FeatureName, State | Format-Table -AutoSize | Out-File $out -Append -Encoding utf8

"=== Services ===" | Out-File $out -Append -Encoding utf8
Get-Service W3SVC, WAS -ErrorAction SilentlyContinue |
  Select-Object Name, Status | Format-Table -AutoSize | Out-File $out -Append -Encoding utf8

"=== App Pools ===" | Out-File $out -Append -Encoding utf8
try {
  Import-Module WebAdministration -ErrorAction Stop
  Get-ChildItem IIS:\AppPools -ErrorAction SilentlyContinue |
    Select-Object Name, State, managedRuntimeVersion, pipelineMode, enable32BitAppOnWin64 |
    Format-Table -AutoSize | Out-File $out -Append -Encoding utf8
  "=== Sites / Apps ===" | Out-File $out -Append -Encoding utf8
  Get-ChildItem IIS:\Sites -ErrorAction SilentlyContinue |
    ForEach-Object {
      "$($_.Name) | id=$($_.Id) | state=$($_.State) | path=$($_.PhysicalPath) | bindings=$(( $_.Bindings.Collection | ForEach-Object { $_.protocol + ':' + $_.bindingInformation }) -join ',')"
    } | Out-File $out -Append -Encoding utf8
  Get-ChildItem IIS:\Sites\Default Web Site -ErrorAction SilentlyContinue |
    ForEach-Object { "APP: $($_.Name) path=$($_.PhysicalPath) pool=$($_.ApplicationPool)" } |
    Out-File $out -Append -Encoding utf8
} catch {
  "WebAdministration module unavailable: $($_.Exception.Message)" | Out-File $out -Append -Encoding utf8
}

"=== Application log: ASP / IIS / Application errors (last 40) ===" | Out-File $out -Append -Encoding utf8
Get-WinEvent -FilterHashtable @{LogName='Application'} -MaxEvents 40 -ErrorAction SilentlyContinue |
  Where-Object { $_.ProviderName -match 'ASP|IIS' -or $_.Message -match 'ASP|w3wp' } |
  Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
  Format-List | Out-File $out -Append -Encoding utf8

"=== DONE ===" | Out-File $out -Append -Encoding utf8
"diag complete"
