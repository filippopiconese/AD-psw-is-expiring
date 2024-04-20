# Program objectives
This script retrieves information about AD groups within a specific OU. It retrieves a CSV file with the list of groups and a text file with the members of each group.

## Program phases

### Variables

Set the needed variables:
- $ouPath -> specifies the organizational unit (OU) path where the Active Directory groups are located.
- $outputFileGroupsOverview -> path to the CSV file where the overview of groups will be exported.
- $outputFileGroupsMembers -> path to the text file where group members will be saved.

### Functions

- Get-GroupMembers -> retrieves the members of a specified Active Directory group and saves their names and distinguished names to a text file. If the group is not found, it logs an error message.

### Execution

- It retrieves a list of Active Directory groups within the specified OU using Get-ADGroup cmdlet.
- It sorts the groups alphabetically based on their SAM account names.
- It exports the overview of groups (name, SAM account name, distinguished name) to a CSV file using Export-Csv.
- It iterates through each group.
    - For each group, it calls the Get-GroupMembers function to retrieve its members and saves them to the text file.

### Output
The output consists of two files:
- AD_OU_Groups.csv -> contains an overview of Active Directory groups within the specified OU, including their names, SAM account names, and distinguished names.
- AD_OU_Groups_With_Members.txt -> Contains the members of each Active Directory group within the specified OU, along with their names and distinguished names. If a group is not found, an error message is logged in this file.