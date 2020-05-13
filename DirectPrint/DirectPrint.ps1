#-----------Set Printer Variables-----------#
$PrinterName = "Resource Copier"
$PrinterIP = "192.168.2.23"
$DriverName = "PCL6 Driver for Universal Print"
$LogFile = "C:\Temp\Logs\AddPrinter.log"


#-----------Start Script-----------#
$Date = Get-Date

#Install drivers delivered with the Intune Package.
start-process .\dpinst64.exe -ArgumentList "/S /SE /SW"
Sleep 10

#Check if the printer driver exists, if not, create it.
If (Get-PrinterDriver $DriverName){
    Write-Output "$Date - Printer Driver $DriverName - Already Exists" | Out-File -Append $LogFile
}
Else{
    Try{
        Add-PrinterDriver -Name $DriverName
        }
    Catch{
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage | Out-File -Append $LogFile
    }
}

#Check if the local printer port exists, if not, create it.
If (Get-PrinterPort "TCP:$($PrinterName)"){
    Write-Output "$Date - Printer Port TCP:$($PrinterName) - Already Exists" | Out-File -Append $LogFile
}
Else {
    Try{
        Add-PrinterPort -Name "TCP:$($PrinterName)" -PrinterHostAddress $PrinterIP
    }
    Catch{
    $ErrorMessage = $_.Exception.Message
    $ErrorMessage | Out-File -Append $LogFile
    }    
}

#Check if the printer exists, if no, add it and set the configuration.
If (Get-Printer $($PrinterName)){
    Write-Output "$Date - Printer $PrinterName - Already Exists" | Out-File -Append $LogFile
}
Else {
    Try{
        Add-Printer -Name "$($PrinterName)" -PortName "TCP:$($PrinterName)" -DriverName $DriverName -Shared:$false 
        Get-Printer $($PrinterName) | Set-PrintConfiguration -DuplexingMode OneSided -Color $false
        }
    Catch{
    $ErrorMessage = $_.Exception.Message
    $ErrorMessage | Out-File -Append $LogFile
    }    
}
