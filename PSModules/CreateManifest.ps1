$manifest = @{
    Path              = '.\Connect-AzAD_Token.psd1'
    RootModule        = '.\1.0\Connect-AzAd_Token.psm1' 
    Author            = 'David Brook'
    CompanyName       = 'EUC365'
    ModuleVersion     = '1.0'
    AliasesToExport = 'CAZADT'
    FunctionsToExport = 'Connect-AzAD_Token'
}
New-ModuleManifest @manifest

