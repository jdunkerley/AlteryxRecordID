param($macroFile, [string]$version = "", [string[]]$folders, [string]$imagePath = "")

$ErrorActionPreference = "Stop"

if (Test-Path $macroFile) {
    $macroFile = Resolve-Path $macroFile
    $name = (Split-Path $macroFile -Leaf) -replace ".yxmc", ""
    $parent = Split-Path $macroFile -Parent
} else {
    Write-Error "File $macroFile not found."
    exit -1
}

Write-Host "Creating $name.yxi in $parent..."

$content = Get-Content -Path $macroFile

Push-Location $parent
$resource = @{}

$matches = ([regex]'<EngineSettings Macro="([^"]+)" />').Matches($content)
foreach ($match in $matches) {
    $rawMatch = $match.Groups[1].Value
    $matchFile = Resolve-Path $rawMatch
    $matchName = Split-Path $matchFile -Leaf
    $resource[$macroFile] = $matchName
    $content = ([string]$content).Replace($match.Value, "<EngineSettings Macro=""Supporting_Files\$matchName"" />")
    Write-Host "Including $matchFile."
}

Pop-Location

[xml]$xmlDoc = $content

$displayName = $xmlDoc.AlteryxDocument.Properties.MetaInfo.Name
if ($displayName -eq $null -or $displayName -eq "") { $displayName = $name }

$author = $xmlDoc.AlteryxDocument.Properties.MetaInfo.Author
if ($author -eq $null -or $author -eq "") { 
    $author = Read-Host -Prompt "Enter Author Name"
}

$description = $xmlDoc.AlteryxDocument.Properties.MetaInfo.Description
if ($description -eq $null -or $description -eq "") { 
    $description = Read-Host -Prompt "Enter Description"
}

$category = $xmlDoc.AlteryxDocument.Properties.MetaInfo.CategoryName
if ($category -eq $null -or $category -eq "") { 
    $category = Read-Host -Prompt "Enter Category"
}

$version = $xmlDoc.AlteryxDocument.Properties.MetaInfo.ToolVersion
if ($version -eq $null -or $version -eq "") { 
    $version = Read-Host -Prompt "Enter Version"
}


$temp = $([System.IO.Path]::GetTempFileName())
Remove-Item $temp
New-Item $temp -type directory | Out-Null
push-location $temp

$configFile = Join-Path "$temp" "Config.xml"

Set-Content $configFile -Value '<?xml version="1.0"?>'
Add-Content $configFile -Value '<AlteryxJavaScriptPlugin>'
Add-Content $configFile -Value '    <Properties>'
Add-Content $configFile -Value '        <MetaInfo>'
Add-Content $configFile -Value "            <Name>$name</Name>"
if ($author -ne $null -and $author -ne "") { 
    Add-Content $configFile -Value "            <Author>$author</Author>"
}
if ($description -ne $null -and $description -ne "") { 
    Add-Content $configFile -Value "            <Description>$description</Description>"
}
if ($category -ne $null -and $category -ne "") { 
    Add-Content $configFile -Value "            <CategoryName>$category</CategoryName>"
}
if ($version -ne $null -and $version -ne "") { 
    Add-Content $configFile -Value "            <ToolVersion>$version</ToolVersion>"
}

$image = $xmlDoc.AlteryxDocument.Properties.RuntimeProperties.MacroImage
if ($image -ne $null -and $image -ne "") { 
    $imageFile = Join-Path "$temp" "$name.png"
    $bytes = [Convert]::FromBase64String($image)
    [IO.File]::WriteAllBytes($imageFile, $bytes)
    Add-Content $configFile -Value "           <Icon>$name.png</Icon>"
}

Add-Content $configFile -Value '        </MetaInfo>'
Add-Content $configFile -Value '    </Properties>'
Add-Content $configFile -Value '</AlteryxJavaScriptPlugin>'

New-Item $name -type directory | Out-Null
Copy-Item -Path $macroFile -Destination (Join-Path $name "$name.yxmc")
if ($resource.Count -gt 0) {
    Set-Content -Path (Join-Path $name "$name.yxmc") -Value $content

    Push-Location $name
    New-Item "Supporting_Files" -type directory | Out-Null

    foreach ($resourcePath in $resource.Keys) {
        Copy-Item -Path $resourcePath -Destination "Supporting_Files"
    }

    Pop-Location
}

Compress-Archive -Path "$temp\*" -DestinationPath "$temp\$name.zip" -Verbose -Update
Move-Item -Path "$temp\$name.zip" -Destination "$parent\$name.yxi"

Pop-Location
Remove-Item $temp -Recurse -Force
