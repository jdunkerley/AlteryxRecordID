param($macroFile)

$ErrorActionPreference = "Stop"

function Add-TempDir() {
    $temp = $([System.IO.Path]::GetTempFileName())
    Remove-Item $temp
    New-Item $temp -type directory | Out-Null
    return $temp
}

function Write-MacroConfigAndImage($macroFile, $config) {
    $content = Get-Content -Path $macroFile
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

    Set-Content $config -Value '<?xml version="1.0"?>'
    Add-Content $config -Value '<AlteryxJavaScriptPlugin>'
    Add-Content $config -Value '    <Properties>'
    Add-Content $config -Value '        <MetaInfo>'
    Add-Content $config -Value "            <Name>$name</Name>"
    if ($author -ne $null -and $author -ne "") { 
        Add-Content $config -Value "            <Author>$author</Author>"
    }
    if ($description -ne $null -and $description -ne "") { 
        Add-Content $config -Value "            <Description>$description</Description>"
    }
    if ($category -ne $null -and $category -ne "") { 
        Add-Content $config -Value "            <CategoryName>$category</CategoryName>"
    }
    if ($version -ne $null -and $version -ne "") { 
        Add-Content $config -Value "            <ToolVersion>$version</ToolVersion>"
    }

    $image = $xmlDoc.AlteryxDocument.Properties.RuntimeProperties.MacroImage
    if ($image -ne $null -and $image -ne "") { 
        $imageFile = Join-Path "$temp" "logo.png"
        $bytes = [Convert]::FromBase64String($image)
        [IO.File]::WriteAllBytes($imageFile, $bytes)
        Add-Content $config -Value "           <Icon>logo.png</Icon>"
    }

    Add-Content $config -Value '        </MetaInfo>'
    Add-Content $config -Value '    </Properties>'
    Add-Content $config -Value '</AlteryxJavaScriptPlugin>'
}

function Add-Resource($resources, $matchFile, $macro) {
    $matchFile = Resolve-Path $match.Groups[1].Value

    if (!$resources.ContainsKey($matchFile)) {
        $matchName = Split-Path $matchFile -Leaf

        if ($macro) {
            $subFolder = $matchName.Replace(".yxmc","")
            $resources.Add($matchFile, (Join-Path $subFolder $matchName))
            New-Item -Name $subFolder -Path $destination -type directory | Out-Null        
            Add-MacroToPackage -macroFile $matchFile -destination (Join-Path $destination $subFolder)
        } else {
            $matchName = Split-Path $matchFile -Leaf
            $resources.Add($matchFile, ".\\$matchName")
            Copy-Item -Path $matchFile -Destination $destination
        }
    }

    return $resources[$matchFile]
}

function Add-MacroToPackage($macroFile, $destination) {
    $resources = @{}

    $content = Get-Content -Path $macroFile
    $parent = Split-Path $macroFile -Parent
    $name = Split-Path $macroFile -Leaf
    $file = Join-Path $destination $name

    Push-Location $parent

    $matches = ([regex]'<EngineSettings Macro="([^"]+)" />').Matches($content)
    foreach ($match in $matches) {
        $content = ([string]$content).Replace($match.Value, ([string]$match.Value).Replace($match.Groups[1].Value, (Add-Resource -resources $resources -matchFile $match.Groups[1].Value -macro $true)))
    }

    $matches = ([regex]'<Example>.*?<File>(.+?)</File>.*?</Example>').Matches($content)
    foreach ($match in $matches) {
        $content = ([string]$content).Replace($match.Value, ([string]$match.Value).Replace($match.Groups[1].Value, (Add-Resource -resources $resources -matchFile $match.Groups[1].Value -macro $false)))
    }

    Pop-Location

    Set-Content -Path $file -Value $content
}

if (Test-Path $macroFile) {
    $macroFile = Resolve-Path $macroFile
    $name = (Split-Path $macroFile -Leaf) -replace ".yxmc", ""
    $parent = Split-Path $macroFile -Parent
} else {
    Write-Error "File $macroFile not found."
    exit -1
}

Write-Host "Creating $name.yxi in $parent..."

$temp = Add-TempDir
Write-Host $temp
Write-MacroConfigAndImage -macroFile $macroFile -config (Join-Path $temp "Config.xml")

New-Item -Name $name -Path $temp -type directory | Out-Null
Add-MacroToPackage -macroFile $macroFile -destination (Join-Path $temp $name)

Compress-Archive -Path "$temp\*" -DestinationPath "$temp\$name.zip" -Verbose -Update
Move-Item -Path "$temp\$name.zip" -Destination "$parent\$name.yxi" -Force

Remove-Item $temp -Recurse -Force