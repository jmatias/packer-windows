$env:PACKER_LOG=0
$env:PACKER_LOG_PATH='C:\logs\windows_10_pro.log'
packer build --only=vmware-iso `
       --var disk_size=136400 `
       windows_10_pro.json
