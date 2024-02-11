# Program objectives
This piece of code helps the company to notify users about AD password expiring.

## Program phases

### Variables

set the needed variables:
- $verbose -> needed if you want to add the password requirements to the email
- $senderEmailAddress -> who sends the email
- $senderPassword -> password of the email sender
- $ccEmailAddress -> this CC email is needed if the password expires within 5 days
- $SMTPserver -> set smtp server
- $DN -> set domain name of the users

### Functions

- PreparePasswordPolicyMail -> write password requirements
- PrepareMailBody -> prepare the body
- SendMail -> set the subject and send the email

### Execution

- The program retrieves the default domain password policy using the Get-ADDefaultDomainPasswordPolicy cmdlet. It then checks if the maximum password age is set (non-zero).
- It then iterates through each user in the Active Directory, obtaining their username (samaccountname) and their email address (mail property).
- It checks if the user's password never expires. If it doesn't, it proceeds with checking the password expiry.
- If a Password Settings Object (PSO) is defined for the user, it retrieves the PSO policy and calculates the password expiry date based on the last password change date (pwdLastSet) and the PSO's maximum password age.
- If no PSO is defined for the user, and the default domain password policy exists, it calculates the password expiry date based on the default domain policy's maximum password age.
- It calculates the number of days until the password expires (delta).
- It checks if delta falls within certain threshold days (30, 25, 20, 15, 10, or 5 days before expiry).
- If the number of days falls within the specified threshold and the user's password doesn't expire, it prepares an email body using the PrepareMailBody function and sends an email notification to the user's email address using the SendMail function.
- If the number of days is within 5 days of expiry, it sets a flag ($addCCUser) to TRUE to set a carbon copy (CC) email.
