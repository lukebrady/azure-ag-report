# Written by Luke Brady
# Univeristy of North Georgia, 2018

# The program configuration specified in azure-ag-report.conf
$configuration = Get-Content -Path $PSScriptRoot\azure-ag-report.conf | ConvertFrom-Json -ErrorAction Stop
# Get-AGProfile is used to retrieve information about the backend pool of the application gateway
# specified in the azure-ag-report.conf configuration file.
function Get-AGProfile {
    Process {
        $auth = Invoke-RestMethod -Method Post https://login.microsoftonline.com/$($configuration.subscription)/oauth2/token -Body @{"grant_type"="client_credentials";"client_id"=$configuration.client_id;"client_secret"=$configuration.client_secret;"resource"="https://management.core.windows.net/"}
        # $uri = "https://management.azure.com/subscriptions/$($Configuration.subscription_id)/resourceGroups/$($Configuration.resource_group)/providers/Microsoft.Network/applicationGateways/$($Configuration.application_gateway)/providers/microsoft.insights/metrics?api-version=2018-01-01"
        # $uri = "https://management.azure.com/subscriptions/$($Configuration.subscription_id)/resourceGroups/$($Configuration.resource_group)/providers/Microsoft.Network/applicationGateways/$($Configuration.application_gateway)/providers/microsoft.insights/Baseline?api-version=2017-11-01-preview"
        $uri = "https://management.azure.com/subscriptions/$($Configuration.subscription_id)/resourceGroups/$($Configuration.resource_group)/providers/Microsoft.Network/applicationGateways/$($Configuration.application_gateway)/providers/microsoft.insights/metrics?metricnames=HealthyHostCount,TotalRequests,FailedRequests&aggregation=total,count,average&interval=PT24H&api-version=2018-01-01"
        $header = @{"Content-Type" = "application/json"; "Authorization" = "Bearer" + " " + $auth.access_token}
        try {
            # Convert the URI in the reHeader into 
            $result = Invoke-RestMethod -Method Get -Uri $uri -Headers $header
        } catch {
            Write-Host "Error: Could not get Azure API data."
        }

    }
    End { return $result }
}

# New-AGReport generates an HTML report based on the API data supplied to the function.
function New-AGReport($result) {
    # Get the average healthy host, failed requests, and total requests from the past
    # 24 hours. The percent of failed requests will also be calculated. 
    $avgHealthyHosts = $result.value[0].timeseries.data.average
    $totalRequests = $result.value[1].timeseries.data.total
    $failedRequests = $result.value[2].timeseries.data.total
    $failedPercent = ($failedRequests / $totalRequests).tostring("P")
    # Now create the HTML report for the application gateway.
    $report = "<h3 style = `"color:#01579b`">$($configuration.application_gateway) Application Gateway Report - Last 24 Hours</h3>"
    $report += "<p><b>Healthy Hosts:</b>    $($avgHealthyHosts)</p>"
    # $report += "<p>Current Connections: $($currentConnections)</p>"
    $report += "<p><b>Total Requests:</b>   $($totalRequests)</p>"
    $report += "<p><b>Failed Requests:</b>  $($failedRequests)</p>"
    $report += "<p><b>Failed Percent:</b>   $($failedPercent)</p>"

    return $report
}