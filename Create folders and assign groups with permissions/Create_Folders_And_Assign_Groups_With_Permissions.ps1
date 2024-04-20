$filePath = "C:\path\to\Shared_Folders_Members.txt"
$groupPrefix = "ID_"
$results = @()
$destinationFolder = "C:\path\to\destination\folder"
$outputFile = "C:\path\to\Create_Folders_And_Assign_Groups_With_Permissions.txt"

Get-Content $filePath | ForEach-Object {
    if ($_ -match "^Folder under analysis: (.+)$") {
        $folderName = $matches[1].Trim()
        $groupName = $groupPrefix + $folderName
        $groupSamAccountName = $groupName -replace " ", "_"

        $fullFolderPath = Join-Path -Path $destinationFolder -ChildPath $folderName

        if (-not (Test-Path $fullFolderPath)) {
            New-Item -ItemType Directory -Path $fullFolderPath | Out-Null
            $results += "Folder created: $fullFolderPath"
        } else {
            $results += "The folder $fullFolderPath already exists."
        }

        $acl = Get-Acl $fullFolderPath

        $permissions = "ReadAndExecute", "Write", "AppendData", "ReadExtendedAttributes", "WriteExtendedAttributes", "CreateDirectories", "CreateFiles", "ExecuteFile", "DeleteSubdirectoriesAndFiles", "ReadAttributes", "WriteAttributes", "WriteData", "ReadPermissions", "Synchronize"

        foreach ($permission in $permissions) {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupSamAccountName, $permission, "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.AddAccessRule($rule)
        }

        Set-Acl $fullFolderPath $acl

        $results += "Assigned advanced permissions to the group $groupSamAccountName on folder $fullFolderPath"
    }
}

$results | Out-File -FilePath $outputFile
