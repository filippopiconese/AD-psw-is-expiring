function Test-ADGroupExists {
    param([string]$groupSamAccountName)
    $group = Get-ADGroup -Filter {SamAccountName -eq $groupSamAccountName} -ErrorAction SilentlyContinue
    return $group
}

function Get-ADGroupMembers {
    param([string]$groupName)
    $members = Get-ADGroupMember -Identity $groupName
    return $members.SamAccountName
}

function Add-UsersToADGroup {
    param([string]$groupName, [string[]]$users)
    $existingMembers = Get-ADGroupMembers -groupName $groupName
    $usersToAdd = $users | Where-Object {$_ -notin $existingMembers}

    foreach ($user in $usersToAdd) {
        Add-ADGroupMember -Identity $groupName -Members $user
    }
}

$ouPath = "OU=Group,OU=Company Org,DC=DOMAIN,DC=COM"
$groupPrefix = "ID_"
$results = @()
$filePath = "C:\path\to\Shared_Folders_Members.txt"
$outputFile = "C:\path\to\Add_AD_OU_Groups_And_Members.txt"

Get-Content $filePath | ForEach-Object {
    if ($_ -match "^Folder under analysis: (.+)$") {
        $folderName = $matches[1].Trim()
        $groupName = $groupPrefix + $folderName
        $groupSamAccountName = $groupName -replace " ", "_"
        $groupObject = Test-ADGroupExists -groupSamAccountName $groupSamAccountName

        if (-not $groupObject) {
            New-ADGroup -Name $groupName -SamAccountName $groupSamAccountName -GroupScope Global -Path "$ouPath" -DisplayName $groupName
            $results += ""
            $results += "Group $groupName created."
        } else {
            $results += ""
            $results += "The group $groupName already exists. Group DN: $($groupObject.DistinguishedName)"
        }
    } elseif ($_ -match "^\s+DOMAIN\\(.+)$") {
        $user = "$($matches[1].Trim())"
        if ($groupObject) {
            $existingMembers = Get-ADGroupMembers -groupName $groupSamAccountName
            if ($user -in $existingMembers) {
                $results += "The user $user is already a member of $groupName."
            } else {
                Add-UsersToADGroup -groupName $groupSamAccountName -users $user
                $results += "The user $user has been added to the group $groupName."
            }
        } else {
            $results += "The group $groupName does not exists. The user $user cannot be added."
        }
    }
}

$results | Out-File -FilePath $outputFile
