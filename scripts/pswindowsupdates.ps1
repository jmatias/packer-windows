

$RegistryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
$RegistryEntry = "DODownloadMode"

"Disabling peer download for Windows updates."
if (-not (Test-Path ($RegistryKey + '\DeliveryOptimization'))) {
    New-Item -Path $RegistryKey -Name DeliveryOptimization
    $RegistryKey += '\DeliveryOptimization'
}
Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value 0