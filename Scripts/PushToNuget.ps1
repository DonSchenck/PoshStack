#
# PushToNuget.ps1
#

# First, we need to find the name of the package
$PackageFile = Get-ChildItem -Filter *.nupkg | Sort-Object name -descending | Select-Object -First 1

# If null or empty, bail immediately


# Now we can push it to nuget.org using the NuGet command line tool
$CMD = "$env:LocalAppData\NuGet\NuGet.exe"
$arg1 = 'push'
$arg2 = $PackageFile.Name
$arg3 =  [System.Environment]::ExpandEnvironmentVariables("%NUGET_APIKEY_PASSWORD%")
& $CMD $arg1 $arg2 $arg3
