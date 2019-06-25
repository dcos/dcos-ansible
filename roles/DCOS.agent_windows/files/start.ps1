$env:HostIP = (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress

$logpath = "c:\mesos-logs\"

If(!(test-path $logpath))
{
      New-Item -ItemType Directory -Force -Path $logpath
}


C:\mesos-binaries\mesos-agent.exe --master=local_ip_master:5050 --appc_store_dir=\\?\C:\images\ --work_dir=\\?\C:\work\ --runtime_dir=\\?\C:\work\ --isolation="windows/cpu,windows/mem,filesystem/windows" --containerizers="mesos,docker" --launcher_dir=\\?\C:\mesos-binaries\ --log_dir=$logpath  --attributes="os:windows" --ip=$env:HostIP --hostname=$(Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/public-ipv4)