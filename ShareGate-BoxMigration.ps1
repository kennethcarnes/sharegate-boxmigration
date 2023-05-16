# Import the ShareGate Module
Import-Module Sharegate

# Specify the path of a CSV file containing a list of emails
$csvFile = "C:\onedrivemigration.csv"

# Import the CSV file as a table
$table = Import-Csv $csvFile -Delimiter ","

# Connect to Box using admin credentials
$box = Connect-Box -Email spdev-customer1@kennethcarnes.com -Admin

# Connect to the SharePoint admin site
$tenant = Connect-Site -Url https://kennethcarnes-admin.sharepoint.com -Browser

# Set the copy settings to incremental update
$copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate

# Provision any necessary OneDrive URLs at least 24 hours in advance
# https://documentation.sharegate.com/hc/en-us/articles/115000641328
$tenant = Connect-Site -Url https://kennethcarnes-admin.sharepoint.com -Browser
$oneDriveUrl = Get-OneDriveUrl -Tenant $tenant -Email spdev-customer2@kennethcarnes.com -ProvisionIfRequired

# Perform incremental migration of Box user data into OneDrive for Business
# https://documentation.sharegate.com/hc/en-us/articles/115000321633-Walkthrough-Import-from-Box-com-to-OneDrive-for-Business-in-PowerShell
Set-Variable dstSite, dstList
foreach ($row in $table) {
    Clear-Variable dstSite
    Clear-Variable dstList
    
    # Get the OneDrive URL for the user's email
    $dstSiteURL = Get-OneDriveUrl -Tenant $tenant -Email $row.Email

    # Connect to the destination OneDrive site
    $dstSite = Connect-Site -Url $dstSiteURL -UseCredentialsFrom $tenant

    # Add the site collection administrator
    Add-SiteCollectionAdministrator -Site $dstSite

    # Get the "Documents" list in the destination site
    $dstList = Get-List -Site $dstSite -name "Documents"

    # Import the Box documents to the destination list
    Import-BoxDocument -Box $box -DestinationList $dstList -UserEmail $row.Email -copysettings $copysettings -NormalMode

    # Remove the site collection administrator
    Remove-SiteCollectionAdministrator -Site $dstSite
}

# Import Box user data into SharePoint site document library
# Connect to Box using admin credentials
$box = Connect-Box -Email spdev-customer1@kennethcarnes.com -Admin

# Connect to the SharePoint site where the data will be imported
$dstSite = Connect-Site -Url "https://kennethcarnes.sharepoint.com/sites/internal" -Browser

# Get the list named "BoxTest" in the destination site
$dstList = Get-List -Name "BoxTest" -Site $dstSite

# Set the copy settings to incremental update
$copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate

# Import Box documents to the SharePoint document library
# using the specified Box user and destination list
Import-BoxDocument -Box $box -UserEmail spdev-customer3@kennethcarnes.com -DestinationList $dstList -NormalMode