do{
    try{
      $user = $null
      $user = Get-ADUser -Identity "" -Server <Server> -ErrorAction Stop
      Write-host -ForegroundColor Green -BackgroundColor Black "User Does Not Exist @ $(Get-Date)"    
    }catch{
        Write-host -ForegroundColor Red -BackgroundColor Black "User Exists @ $(Get-Date)"
    }
  }until($User)


  do{
    try{
      $Computer = $null
      $Computer = Get-ADComputer -Identity "" -Server <Server> -ErrorAction Stop
      Write-host -ForegroundColor Green -BackgroundColor Black "Computer Does Not Exist @ $(Get-Date)"    
    }catch{
        Write-host -ForegroundColor Red -BackgroundColor Black "Computer Exists @ $(Get-Date)"
    }
  }until($Computer)