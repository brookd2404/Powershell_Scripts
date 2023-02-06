# Create an array of objects 
$array = Import-Csv -Path '<CSVLocation>'

# Calculate the total number of items in the array 
$TotalArrayItems = $array.count

# Calculate the percentage of items to be split into each category
$testCategoryPercentage = 10
$pilotCategoryPercentage = 20
$productionCategoryPercentage = 70

# Calculate the number of items to be split into each category
$testCategoryItems = [Math]::Round($TotalArrayItems * $testCategoryPercentage/100)
$pilotCategoryItems = [Math]::Round($TotalArrayItems * $pilotCategoryPercentage/100)
$productionCategoryItems = [Math]::Round($TotalArrayItems * $productionCategoryPercentage/100)

# Create empty arrays for each category 
$testCategory = @()
$pilotCategory = @()
$productionCategory = @()

# Iterate over the array and add the items to the respective categories
for($i=0;$i -lt $TotalArrayItems;$i++) {
    if(($i -lt $testCategoryItems) -and ([System.String]::IsNullOrEmpty($array[$i].category))) {
        $testCategory += $array[$i]
    }
    elseif(($i -lt ($testCategoryItems + $pilotCategoryItems)) -and ([System.String]::IsNullOrEmpty($array[$i].category))) {
        $pilotCategory += $array[$i]
    }
    else {
        $productionCategory += $array[$i]
    }
}

foreach($item in $testCategory){$item.category = "Test"}
foreach($item in $pilotCategory){$item.category = "Pilot"}
foreach($item in $productionCategory){$item.category = "Production"}

$outputArray = @()
$outputArray += $testCategory
$outputArray += $pilotCategory
$outputArray += $productionCategory
