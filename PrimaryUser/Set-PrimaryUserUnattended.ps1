# Application (client) ID, tenant ID and secret
$clientId = "YOUR CLIENT ID HERE"
$clientSecret = "YOUR CLIENT SECRET"
$tenantid = "YOUR TENANT ID"

####################################################

function Get-AuthToken {
    $script:graphBaseURI = "https://graph.microsoft.com/beta"

    # Construct URI
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

    # Construct Body
    $body = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }

    # Get OAuth 2.0 Token
    $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing

    # Access Token
    $script:token = ($tokenRequest.Content | ConvertFrom-Json).access_token
    
    $ExpiresOn = [DateTimeOffset](get-date).AddMinutes(3599)

    $authHeader = @{
    'Content-Type'='application/json'
    'Authorization'="Bearer " + $token
    'ExpiresOn'= $ExpiresOn
    }

    return $authHeader
}


####################################################

function Get-Win10IntuneManagedDevice {

<#
.SYNOPSIS
This gets information on Intune managed devices
.DESCRIPTION
This gets information on Intune managed devices
.EXAMPLE
Get-Win10IntuneManagedDevice
.NOTES
NAME: Get-Win10IntuneManagedDevice
#>

[cmdletbinding()]

param
(
[parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
[string]$deviceName
)
    
    $graphApiVersion = "beta"

    try {

        if($deviceName){

            $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
	        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" 

            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

        else {

            $Resource = "deviceManagement/managedDevices?`$filter=(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
	    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            
            $DeviceResults = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
            $Results = @()
            $Results += $DeviceResults.value

            $NextPage = $DeviceResults.'@odata.nextLink'
            while($null -ne $NextPage) {

                $Additional = Invoke-RestMethod -Uri $NextPage -Headers $authToken -Method Get
                if($NextPage) {
                    $NextPage = $Additional.'@odata.nextLink'
                }
                $Results += $Additional.value
            }
            $Results
        }

	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-IntuneManagedDevices error"
	}

}

####################################################

Function Get-AADUser(){

<#
.SYNOPSIS
This function is used to get AAD Users from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any users registered with AAD
.EXAMPLE
Get-AADUser
Returns all users registered with Azure AD
.EXAMPLE
Get-AADUser -userPrincipleName user@domain.com
Returns specific user by UserPrincipalName registered with Azure AD
.NOTES
NAME: Get-AADUser
#>

[cmdletbinding()]

param
(
    $userPrincipalName,
    $Property
)

# Defining Variables
$graphApiVersion = "v1.0"
$User_resource = "users"
    
    try {
        
        if($userPrincipalName -eq "" -or $userPrincipalName -eq $null){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        
        }

        else {
            
            if($Property -eq "" -or $Property -eq $null){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
            Write-Verbose $uri
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

            }

            else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
            Write-Verbose $uri
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            }

        }
    
    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

function Get-IntuneDevicePrimaryUser {

<#
.SYNOPSIS
This lists the Intune device primary user
.DESCRIPTION
This lists the Intune device primary user
.EXAMPLE
Get-IntuneDevicePrimaryUser
.NOTES
NAME: Get-IntuneDevicePrimaryUser
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [string] $deviceId
)
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices"
	$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" + "/" + $deviceId + "/users"

    try {
        
        $primaryUser = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        return $primaryUser.value."id"
        
	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-IntuneDevicePrimaryUser error"
	}
}

####################################################

function Set-IntuneDevicePrimaryUser {

<#
.SYNOPSIS
This updates the Intune device primary user
.DESCRIPTION
This updates the Intune device primary user
.EXAMPLE
Set-IntuneDevicePrimaryUser
.NOTES
NAME: Set-IntuneDevicePrimaryUser
#>

[cmdletbinding()]

param
(
[parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$IntuneDeviceId,
[parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$userId
)
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"

    try {
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $userId

        $id = "@odata.id"
        $JSON = @{ $id="$userUri" } | ConvertTo-Json -Compress

        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Set-IntuneDevicePrimaryUser error"
	}

}

####################################################

#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

        # Defining User Principal Name if not present

        #if($User -eq $null -or $User -eq ""){
        #    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        #    Write-Host
        #}

        $global:authToken = Get-AuthToken # -User $User
    }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    #if($User -eq $null -or $User -eq "") {
    #    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    #    Write-Host
    #}

    # Getting the authorization token
    $global:authToken = Get-AuthToken # -User $User
}

#endregion

####################################################

#Get All Windows 10 Intune Managed Devices for the Tenant
$Devices = Get-Win10IntuneManagedDevice

$targetdevices = $devices | Where-Object {$_.deviceName -like "LAP*"}


Foreach ($Device in $targetdevices){ 

        Write-Host "Device name:" $device."deviceName" -ForegroundColor Cyan
        $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -deviceId $Device.id

        #Check if there is a Primary user set on the device already
        if($IntuneDevicePrimaryUser -eq $null){

            Write-Host "No Intune Primary User Id set for Intune Managed Device" $Device."deviceName" -f Red 

        }

        else {
            $PrimaryAADUser = Get-AADUser -userPrincipalName $IntuneDevicePrimaryUser
            Write-Host "Intune Device Primary User:" $PrimaryAADUser.displayName

        }

        #Get the objectID of the last logged in user for the device, which is the last object in the list of usersLoggedOn
        $LastLoggedInUser = ($Device.usersLoggedOn[-1]).userId

        #Using the objectID, get the user from the Microsoft Graph for logging purposes
        $User = Get-AADUser -userPrincipalName $LastLoggedInUser
    
            #Check if the current primary user of the device is the same as the last logged in user
            if($IntuneDevicePrimaryUser -notmatch $User.id){

                #If the user does not match, then set the last logged in user as the new Primary User
                $SetIntuneDevicePrimaryUser = Set-IntuneDevicePrimaryUser -IntuneDeviceId $Device.id -userId $User.id -ErrorAction SilentlyContinue

                if($SetIntuneDevicePrimaryUser -eq ""){

                    Write-Host "User"$User.displayName"set as Primary User for device '$($Device.deviceName)'..." -ForegroundColor Green

                }

            }

            else {
                #If the user is the same, then write to host that the primary user is already correct.
                Write-Host "The user '$($User.displayName)' is already the Primary User on the device..." -ForegroundColor Yellow

            }

    Write-Host

}
