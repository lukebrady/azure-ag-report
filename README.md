# azure-ag-report
Reporting for Azure Application Gateway.

### To Use:
```powershell
$pr = Get-AGProfile
$report = New-AGReport($pr)
Send-MailMessage -Body $report -BodyAsHtml -From <fromaddress> `
                     -Subject "Application Gateway Report" -SmtpServer <smtpserver> -To $configuration.recipients
```