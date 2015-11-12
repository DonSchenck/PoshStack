#
# Build.ps1
#

# If NUGET is NOT installed on the build machine, install it here and now.
if(!( test-path $env:LocalAppData\NuGet\NuGet.exe)) {
  # download nuget
  Invoke-WebRequest 'https://www.nuget.org/nuget.exe' -OutFile "$($env:LocalAppData)\NuGet\NuGet.exe"
}

# Run PACK to build the Nuget package
$CMD = "$env:LocalAppData\NuGet\NuGet.exe"
$arg1 = 'pack'
$arg2 = '..\PoshStack.nuspec'
$arg3 = "-NoPackageAnalysis"

& $CMD $arg1 $arg2 $arg3