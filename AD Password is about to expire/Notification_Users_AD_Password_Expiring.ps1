# Variables
$verbose = $true
$senderEmailAddress = "email@example.com"
$senderPassword = "password"
$ccEmailAddress = "another.email@example.com"
$SMTPserver = "smtp.server.com"
$DN = "OU=Users,OU=Company,DC=example,DC=local"

# Functions
function PreparePasswordPolicyMail ($ComplexityEnabled, [int] $MaxPasswordAge, [int] $MinPasswordAge, [int] $MinPasswordLength, [int] $PasswordHistoryCount) {
    $verbosemailBody = "`r`nMinimum password requirements:`r`n"
    $verbosemailBody += "`t- Maximum duration = " + $MaxPasswordAge + " days`r`n"
    $verbosemailBody += "`t- Minimum length = " + $MinPasswordLength + " characters`r`n"
    $verbosemailBody += "`t- Number of previous passwords remembered = " + $PasswordHistoryCount + "`r`n"
    $verbosemailBody += "`t- Cannot contain more than two consecutive characters of the user's full name or user account name`r`n"
    $verbosemailBody += "`t- Must contain characters from at least three of the following four categories:`r`n"
    $verbosemailBody += "`t`t- Uppercase English alphabet characters (A-Z)`r`n"
    $verbosemailBody += "`t`t- Lowercase English alphabet characters (a-z)`r`n"
    $verbosemailBody += "`t`t- Decimal digits (0-9)`r`n"
    $verbosemailBody += "`t`t- Non-alphabetic characters, e.g., !, $, #, %`r`n"

    return $verbosemailBody
}

function PrepareMailBody ($userGivenName, $samaccountname, $delta, $verbose, [SecureString] $passwordPolicy) {
    $mailBody = "Hello " + $userGivenName + " (" + $samaccountname + "),`r`n`r`n"
    $mailBody += "Your password expires in " + $delta + " days. We recommend changing your password before the expiration to avoid account lockout.`r`n`r`n"
    $mailBody += "To change your password, follow this procedure:`r`n"
    $mailBody += "`t1. Press CTRL + ALT + DEL keys`r`n"
    $mailBody += "`t2. Click Change Password`r`n"
    $mailBody += "`t3. Enter 'COMPANY\FirstName.LastName' and follow the procedure`r`n"
    if ($verbose) {
        $mailBody += PreparePasswordPolicyMail $passwordPolicy.ComplexityEnabled $passwordPolicy.MaxPasswordAge.Days $passwordPolicy.MinPasswordAge.Days $passwordPolicy.MinPasswordLength $passwordPolicy.PasswordHistoryCount
    }
    $mailBody += "`r`nThank you and have a great day."
    $mailBody += "`r`nDream Support Team"

    return $mailBody
}

function SendMail ($SMTPserver, $senderEmailAddress, [SecureString] $senderPassword, $userEmailAddress, $mailBody, $addCCUser) {
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($SMTPserver, 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($senderEmailAddress, $senderPassword)
    $msg.From = $senderEmailAddress
    $msg.To.Add($userEmailAddress)
    if ($addCCUser) {
        $msg.Cc.Add($ccEmailAddress)
    }
    $msg.Subject = "Your password is expiring"
    $msg.Body = $mailBody
    $smtp.Send($msg)
}

# Main
$domainPolicy = Get-ADDefaultDomainPasswordPolicy
$passwordExpiryDefaultDomainPolicy = $domainPolicy.MaxPasswordAge.Days -ne 0

if ($passwordExpiryDefaultDomainPolicy) {
    $defaultDomainPolicyMaxPasswordAge = $domainPolicy.MaxPasswordAge.Days
}

foreach ($user in (Get-ADUser -SearchBase $DN -Filter * -properties mail)) {
    $samaccountname = $user.samaccountname
    $PSO = Get-ADUserResultantPasswordPolicy -Identity $samaccountname
    $addCCUser = $FALSE
    $PasswordNeverExpires = (Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties PasswordNeverExpires).PasswordNeverExpires
    if (!$PasswordNeverExpires) {
        if ($null -ne $PSO) {
            $PSOpolicy = Get-ADUserResultantPasswordPolicy -Identity $samaccountname
            $PSOMaxPasswordAge = $PSOpolicy.MaxPasswordAge.days
            $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)
            $expirydate = ($pwdlastset).AddDays($PSOMaxPasswordAge)
            $delta = ($expirydate - (Get-Date)).Days
            $comparionresults = ($delta -eq 30) -OR ($delta -eq 25) -OR ($delta -eq 20) -OR ($delta -eq 15) -OR ($delta -eq 10) -OR ($delta -le 5)
            if ($comparionresults) {
                if ($delta -le 5) {
                    $addCCUser = $TRUE
                }
                $userEmailAddress = $user.mail
                $mailBody = PrepareMailBody $user.GivenName $samaccountname $delta $verbose $PSOpolicy
                SendMail $SMTPserver $senderEmailAddress $senderPassword $userEmailAddress $mailBody $addCCUser
            }
        }
        else {
            if ($passwordExpiryDefaultDomainPolicy) {
                $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)
                $expirydate = ($pwdlastset).AddDays($defaultDomainPolicyMaxPasswordAge)
                $delta = ($expirydate - (Get-Date)).Days
                $comparionresults = ($delta -eq 30) -OR ($delta -eq 25) -OR ($delta -eq 20) -OR ($delta -eq 15) -OR ($delta -eq 10) -OR ($delta -le 5)
                if ($comparionresults) {
                    if ($delta -le 5) {
                        $addCCUser = $TRUE
                    }
                    $userEmailAddress = $user.mail
                    $mailBody = PrepareMailBody $user.GivenName $samaccountname $delta $verbose $domainPolicy
                    SendMail $SMTPserver $senderEmailAddress $senderPassword $userEmailAddress $mailBody $addCCUser
                }
            }
        }
    }
}