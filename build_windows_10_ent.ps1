$env:PACKER_LOG=0
$env:PACKER_LOG_PATH='C:\logs\windows_10_ent.log'
packer build --only=vmware-iso --var iso_checksum=9ef81b6a101afd57b2dbfa44d5c8f7bc94ff45b51b82c5a1f9267ce2e63e9f53 `
       --var iso_url="https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso" `
       --var disk_size=136400 --var windows10_edition=ent `
       windows_10.json
