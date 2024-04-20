# Program objectives
This script is designed to retrieve the users who have access to folders within a specified share path and save the results to a text file.

## Program phases

### Variables

Set the needed variables:
- $sharePath -> the share path to analyse
- $outputFile -> the path where to save the results

### Functions

- Get-FolderUsers -> It is the main function that contains all the features of the program

### Execution

- It sets the content of the output file to include the share folder path.
- It retrieves a list of folder names within the specified folder path.
- For each folder:
    - It attempts to retrieve the Access Control List (ACL) for the folder.
    - It iterates through the access rules and collects the users with access.
    - It writes the list of users with access to the output file, excluding certain system users.
    - If an error occurs during this process (e.g., due to lack of permissions), it indicates that in the output file.

### Output
A text file is created containing the analyzed share, the analyzed folders and, for each folder, the relative members net of the system ones not taken into consideration.