---
layout: post
title:  Running Azure Insights Log Queries Locally
date:   2019-10-29 08:50:22 +0300
tags:   azure, powershell
---

[Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) is a tool to monitor your application running in Azure cloud.

![Azure Application Insights Architecture](https://docs.microsoft.com/en-us/azure/azure-monitor/app/media/app-insights-overview/diagram.png "source: https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview")

Custom queries to Application Insights logs are written in [Kusto](https://docs.microsoft.com/en-us/azure/kusto/query/index). You can run these queries in Azure Portal, but for this [Stack Overflow question](https://stackoverflow.com/questions/52373606/how-to-run-an-azure-log-analytics-query-from-a-powershell-script-non-interactive/57409972#57409972) I wrote a solution how to execute these locally.

You need the Application Insights extension to az:
{% highlight powershell %}
az extension add -n application-insights
{% endhighlight %}

Then you can run queries like this:
{% highlight powershell %}
az monitor app-insights query --apps "$my-app-name" --resource-group "$my-resource-group" --offset 24H --analytics-query 'requests | summarize count() by bin(timestamp, 1h)'
{% endhighlight %}


I wrote a script to run kusto scripts from a file and get the result as a Powershell object:

_Search-AppInsights.psi_:
{% highlight powershell %}
<#
.SYNOPSIS

Run query in application insights and return Powershell table

.PARAMETER filename

File name of kusto query

.PARAMETER app 

Application Insights instance name

.PARAMETER rg

Resource group name

.EXAMPLE

Search-AppInsights -filename file.kusto -app my-app-name -rg my-resource-group-name

#>
param([string] $filename, [string]$app, [string]$rg)

$query = Get-Content $filename
$data = az monitor app-insights query --apps "$app" --resource-group "$rg" --offset 48H --analytics-query "$query" | ConvertFrom-Json
$cols = $data.tables.columns | % {  $_.name }
$data.tables.rows | % {
    $obj = New-Object -TypeName psobject
    for ($i=0; $i -lt $cols.Length; $i++) {
	$obj | Add-Member -MemberType NoteProperty -Name $cols[$i] -Value $_[$i]
    }
    $obj
}
{% endhighlight %}

For example if we use the [demo instance](https://analytics.applicationinsights.io/demo#/query/results/table) data we could count the 3 hour request counts for each URI:

{% highlight bash %}
$ cat count_rows.kusto
requests
| summarize rows=count() by url, name, bin(timestamp, 3h)
$ Search-AppInsights.ps1 -app my-application-insights-instance -rg resource-group-name -filename count_rows.kusto
timestamp                       url                                             name		        rows
------                          ----                                            ---------               ----
9/13/2019, 6:00:00.000 AM	http://fabrikamfiberapp.azurewebsites.net/	GET Home/Index	62	
9/13/2019, 6:00:00.000 AM	http://fabrikamfiberapp.azurewebsites.net/Scripts/applicationinsights-channel-js.js	GET /Scripts/applicationinsights-channel-js.js	1	
9/13/2019, 6:00:00.000 AM	http://fabrikamfiberapp.azurewebsites.net/Scripts/jquery-ui-1.8.11.js	GET /Scripts/jquery-ui-1.8.11.js	1	
9/13/2019, 6:00:00.000 AM	http://fabrikamfiberapp.azurewebsites.net/Scripts/knockout.mapping-latest.js	GET /Scripts/knockout.mapping-latest.js	1	
9/13/2019, 6:00:00.000 AM	http://fabrikamfiberapp.azurewebsites.net/Content/themes/base/jquery.ui.all.css	GET /Content/themes/base/jquery.ui.all.css	1	
9/13/2019, 6:00:00.000 AM	http://fabrikamfiberapp.azurewebsites.net/Customers/Details/8469	GET Customers/Details	15
{% endhighlight %}

For the Emacs users out there, I also wrote a [kusto-mode](https://github.com/ration/kusto-mode.el) for syntax highlighting.

