function Get-FolderUsers {
    param (
        [string]$FolderPath,
        [string]$outputFile
    )

    Set-Content -Path $outputFile -Value ("Share under analysis `t$folderPath")

    $folderMembers = Get-ChildItem -Path $FolderPath | Select-Object Name

    foreach ($member in $folderMembers) {
        $folderName = "$($member.Name)"
        Add-Content -Path $outputFile -Value ""
        Add-Content -Path $outputFile -Value ("Folder under analysis: $folderName")

        try {
            $acl = Get-Acl -Path "$folderPath\$folderName" -ErrorAction SilentlyContinue
            $accessRules = $acl.Access
            $usersWithAccess = @()

            foreach ($accessRule in $accessRules) {
                if ($accessRule.IdentityReference.Value -notlike "BUILTIN\*" -and $accessRule.IdentityReference.Value -notlike "NT AUTHORITY\*" -and $accessRule.IdentityReference.Value -notlike "DOMAIN\*" -and $accessRule.IdentityReference.Value -ne "Everyone") {
                    $usersWithAccess += $accessRule.IdentityReference.Value
                }
            }

            $uniqueUsers = $usersWithAccess | Get-Unique

            Add-Content -Path $outputFile -Value ("- Users:")
            foreach ($userSID in $uniqueUsers) {
                if ($userSID -match '^([^\\]+)\\([^\\]+)$') {
                    Add-Content -Path $outputFile -Value ("`t$userSID")
                }
            }
        } catch {
            Add-Content -Path $outputFile -Value ("- ERROR: NO Read permission")
        }
    }
}

$sharePath = "\\SRV-ME\sharename"
$outputFile = "C:\path\to\Shared_Folders_Members.txt"

Get-FolderUsers -FolderPath $sharePath -outputFile $outputFile