<#
    This script will ask for a server and move it to the disabled servers OU
    and then remove the server from the domain and restart it. Credentials are handled
    by Get-Credentials. The first run will use the -whatif glag then it will ask to confirm
    the action, make sure to double check the output.
#>

# Ask for the server name and get its GUID
$server = Read-Host -Prompt "Server Name"
$server_guid = (Get-ADObject -Filter {name -Like $server}).ObjectGUID
$disabledOU = "OU=Servers,OU=Disabled Objects,DC=ad,DC=acme,DC=com"

# If the GUID comes back empty it means no server was found with that name
if ($server_guid -eq $null) {
    echo "Server not found"
    exit
}

# Ask for credentials
$creds = Get-Credential

# Do a test run of the operations
Move-ADObject -TargetPath $disabledOU -Identity $server_guid -Credential $creds -WhatIf
Remove-Computer -ComputerName $server -Credential $creds -Verbose -Restart -PassThru -WhatIf

# Aks for confirmation to proceed
$confirm = Read-Host -Prompt "Continue? Y/N"
if ($confirm -eq "Y") {
    Move-ADObject -TargetPath $disabledOU -Identity $server_guid -Credential $creds -whatif

    # It is easier to run the command from the local machine so we use Invoke-Command for this
    Invoke-Command -ComputerName $server -Credential $creds -ScriptBlock {
        Remove-Computer -UnjoinDomainCredential $creds -Verbose -Restart -PassThru -whatif
    }
} else {
    exit
}
