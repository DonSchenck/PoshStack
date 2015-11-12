Remove-Module poshstack
import-module poshstack
Clear
ls
$a = "<style>"
$a = $a + "BODY{background-color:peachpuff;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
$a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
$a = $a + "</style>"

Get-OpenStackComputeServerImage -Account rackiad  | ConvertTo-Html -head $a | Out-File C:\Temp\get_cloudserverimages.html
#Get-CloudServerImages -Account demo | WHERE {$_.name -eq 'Windows Server 2008 R2 SP1' } | ConvertTo-Html -head $a | Out-File C:\Temp\get_cloudserverimages.html
Invoke-Expression C:\Temp\get_cloudserverimages.html