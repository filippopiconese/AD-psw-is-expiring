function Get-GroupMembers {
    param(
        [string]$groupName,
        [string]$outputFile
    )
    
    try {
        $members = Get-ADGroupMember -Identity $groupName -ErrorAction Stop
        
        Add-Content -Path $outputFile -Value ("Members of $groupName :")
        $members | Select-Object Name, DistinguishedName | ForEach-Object {
            Add-Content -Path $outputFile -Value $_
        }
        Add-Content -Path $outputFile -Value ""
    } catch {
        Add-Content -Path $outputFile -Value ("ERROR: Group $groupName not found.")
        Add-Content -Path $outputFile -Value ""
    }
}

$ouPath = "OU=Group,OU=Company Org,DC=DOMAIN,DC=COM"
$outputFileGroupsOverview = "C:\path\to\AD_OU_Groups.csv"
$outputFileGroupsMembers = "C:\path\to\Get_AD_OU_Groups_And_Members.txt"

$groups = Get-ADGroup -Filter * -SearchBase "$ouPath" | Sort-Object SamAccountName
$groups | Select-Object name, SamAccountName, DistinguishedName | Export-Csv -Path $outputFileGroupsOverview -NoTypeInformation -Force

foreach ($group in $groups) {
    Get-GroupMembers -groupName $group.SamAccountName -outputFile $outputFileGroupsMembers
}
