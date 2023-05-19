function Invoke-MyFunction {
    <#
        .SYNOPSIS
        migrates stuf from a to b.

        .DESCRIPTION
        migrates stuff from a to b.

        .PARAMETER EmailAddress
        Description of Parameter.

        .EXAMPLE
        Invoke-MyFunction -CsvPath C:\temp\emails.csv

        Explanation of example
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "List of email addresses to migrate")]
        [string]$CsvPath
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name) :: BEGIN :: $(Get-Date)"
    }

    process {
        Write-Verbose "Importing the ShareGate Module"
        Import-Module Sharegate

        $PathExists = Test-Path -Path $CsvPath
        if (-not $PathExists) {
            throw "The path $CsvPath does not exist"
        }

        $Emails = (Import-Csv -Path $CsvPath).Emails

        Write-Verbose "Connecting to the box account"
        $box = Connect-Box -Email spdev-customer1@kennethcarnes.com -Admin

        Write-Verbose "Connecting to the sharepoint account"
        $tenant = Connect-Site -Url https://kennethcarnes-admin.sharepoint.com -Browser

        Write-Verbose "Setting the copy settings to incremental update"
        $copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate

        # Provision any necessary OneDrive URLs at least 24 hours in advance
        # https://documentation.sharegate.com/hc/en-us/articles/115000641328
        $tenant      = Connect-Site -Url https://kennethcarnes-admin.sharepoint.com -Browser
        $oneDriveUrl = Get-OneDriveUrl -Tenant $tenant -Email spdev-customer2@kennethcarnes.com -ProvisionIfRequired

        # Perform incremental migration of Box user data into OneDrive for Business
        # https://documentation.sharegate.com/hc/en-us/articles/115000321633-Walkthrough-Import-from-Box-com-to-OneDrive-for-Business-in-PowerShell
        foreach ($Email in $Emails) {
            Write-Verbose "Working on $Email"

            # Get the OneDrive URL for the user's email
            Write-Verbose "$Email :: Getting the OneDrive drive URL"
            $dstSiteURL = Get-OneDriveUrl -Tenant $tenant -Email $Email
        
            # Connect to the destination OneDrive site
            Write-Verbose "$Email :: Connecting to the destination OneDrive site"
            $dstSite = Connect-Site -Url $dstSiteURL -UseCredentialsFrom $tenant
        
            # Add the site collection administrator
            Add-SiteCollectionAdministrator -Site $dstSite
        
            # Get the "Documents" list in the destination site
            $dstList = Get-List -Site $dstSite -name "Documents"
        
            # Import the Box documents to the destination list
            Import-BoxDocument -Box $box -DestinationList $dstList -UserEmail $Email -copysettings $copysettings -NormalMode
        
            # Remove the site collection administrator
            Remove-SiteCollectionAdministrator -Site $dstSite
        }
    }

    end {
        Write-Verbose "$($MyInvocation.MyCommand.Name) :: END   :: $(Get-Date)"
    }
}