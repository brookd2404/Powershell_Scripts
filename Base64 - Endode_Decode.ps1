param (
    $ToBase,
    $FromBase64 
)

IF ($ToBase) {
    $Return = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ToBase))
}

If($FromBase64) {
    $return = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($FromBase64))
}

$Return