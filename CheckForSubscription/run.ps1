#Pwsh Azure function
#Pre-req: To be configured with a ManagedId to read subscriptions from a ManagementGroup
#To be called from an Azure DevOps Environment Gate
#Will callback to the Azure DevOps API to get build artifacts
#Expects 1 artifact with a file called subscriptionname.txt
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Hydrate params from body of the request.
$buildId = $Request.Body.buildId
$projectId = $Request.Body.ProjectId
$ADOPROJ = $Request.Body.Project
$uri = $Request.Body.URI

# Write some of the parameters to the logs
Write-Verbose "Received BuildId: $buildId"
Write-Verbose "Received Uri: $uri"
Write-Verbose "Received project: $ADOPROJ"
Write-Verbose "Received projectId: $projectId"

#Basic validation of passed parameters
if($buildId -eq $NULL) { Write-Error "buildId not provided"; Return }
if($projectId -eq $NULL) { Write-Error "ProjectId not provided"; Return }
if($ADOPROJ -eq $NULL) { Write-Error "Project not provided"; Return }
if($uri -eq $NULL) { Write-Error "URI not provided"; Return }

#Acquire the PAT token from either body parameter or from the App Settings of the Azure Function
if (-not $Request.Body.AuthToken) {
    try{
        Write-Verbose "Setting PAT token from AppSettings"
        $patenv=ls env:APPSETTING_ADO_PAT
        $pat =  $patenv.Value
    } catch {
        $failure = $_.Exception.Message
        Write-Error "[ERROR] Failed to GET PAT token from AppSettings or Request Body. $failure"
        Return
    }
} else {
    Write-Verbose "Setting token from Request Body Parameter"
    $pat = $Request.Body.AuthToken
}
if($pat.Length -lt 1) { Write-Error "WARNING: PAT Token is empty"; Return}

#Base64 encode the PAT token, ready for a HTTP request header
$base64AuthInfo= [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))

#Figure out the BaseUri from URI. TODO. Write a Regex for this.
if($uri -like "https://dev.azure.com/*") {
    Write-Verbose "(newer dev.azure.com URI detected)"

    $baseApiUrl="$($uri)$ADOPROJ/_apis"

} elseif($uri -like "*.visualstudio.com/*") {
    Write-Verbose "(older VSTS URI detected)"
    $ADOORG=$uri.replace("https://","").replace(".visualstudio.com/","")

    $baseApiUrl="https://dev.azure.com/$ADOORG/$ADOPROJ/_apis"
}
Write-Verbose "Using ADO Org: $ADOORG"

#Write-Host "Getting build $BUILDID"
#$BuildURL="$baseApiUrl/build/builds/$($BUILDID)?api-version=6.0"
#Write-Verbose "Calling $BuildURL"
#$buildresponse=Invoke-RestMethod -Uri $BuildURL -Headers @{Authorization = "Basic {0}" -f $base64AuthInfo} -Method Get
#Write-Output $buildresponse

Write-Host "Getting build Artifacts for build $BUILDID"
$ArtifactListURL="$baseApiUrl/build/builds/$($BUILDID)/artifacts?api-version=6.0"
Write-Verbose "Calling $ArtifactListURL"
$artifactListReponse=Invoke-RestMethod -Uri $ArtifactListURL -Headers @{Authorization = "Basic {0}" -f $base64AuthInfo} -Method Get
#Write-Output $artifactListReponse

if ($artifactListReponse.count -eq 0) {
    Write-Error "No artifacts found on pipeline build $BUILDID"; Return
}

if ($artifactListReponse.count =1) {
    $artifactname=$artifactListReponse.value[0].name
} else {
    Write-Error "$($artifactListReponse.count) artifacts found. Expected 1."; Return
}

#Write-Host "Getting build Artifact: $artifactname"
#$ArtifactURL="$baseApiUrl/build/builds/$($BUILDID)/artifacts?artifactName=$($artifactname)&api-version=6.0"
#Write-host "Calling $ArtifactURL"
#$artifactReponse=Invoke-RestMethod -Uri $ArtifactURL -Headers @{Authorization = "Basic {0}" -f $base64AuthInfo} -Method Get
#Write-Output $artifactReponse
#$downloadUrl=$artifactReponse.resource.downloadUrl

$downloadUrl=$artifactListReponse.value[0].resource.downloadUrl
Write-Verbose "Downloading artifact from $downloadUrl"
$dlReponse=Invoke-RestMethod -Uri $downloadUrl -Headers @{Authorization = "Basic {0}" -f $base64AuthInfo} -Method Get -OutFile download.zip

if (test-path download.zip) {
    Write-Verbose "Expanding zip file"
    $zippath=join-path $env:TEMP (new-guid).guid "zipout"
    Expand-Archive -path download.zip -destinationPath $zippath -force

    $artifactFilePath="drop/subscriptionname.json"
    $jsonfilepath=join-path $zippath $artifactFilePath
    if (test-path $jsonfilepath) {
        Write-Verbose "Parsing subscriptionname.json"
        $subnamejson=Get-Content $jsonfilepath -raw | ConvertFrom-Json
        $subname=$subnamejson.Subscription
        Write-Output "Artifact Subscription Name: $subname"
    } else {
        Write-Error "Could not find file $artifactFilePath in downloaded artifact"; Return
    }
} else {
    Write-Error "Could not find downloaded artifact"; Return
}

#Now use Azure cmdlets to see if the subscription has been created
Write-Host "Searching Azure for Subscription $subname"
$subSearch=Get-AzSubscription -SubscriptionName $subname

if ($subSearch -ne $Null) {
    Write-Verbose "Found subscription $subname"
    Write-Verbose $subSearch

    $returnObj = New-Object PSObject -Property ([Ordered]@{subName=$subName; subfound=$true; subId=$subSearch.Id; subState=$subSearch.State })
} else {
    Write-Output "Not Found subscription $subname try again later"
    $subId = ""
    $returnObj = New-Object PSObject -Property ([Ordered]@{subName=$subName.tostring(); subfound=$false; subId=$subId })
}

Write-Host $returnObj

#Any cleanup
$pat = $NULL

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $returnObj
})
