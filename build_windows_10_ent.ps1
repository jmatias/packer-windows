$env:PACKER_LOG=1
$env:PACKER_LOG_PATH='C:\logs\windows_10_ent.log'

packer build --only=vmware-iso `
       --var disk_size=136400 `
       windows_10_enterprise.json
