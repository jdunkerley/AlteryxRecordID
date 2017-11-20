param($macroFile, $targetFolder)
$ErrorActionPreference = "Stop"

function Add-Connection($node, $config) {
    $iname = $node.Properties.Configuration.Name
    $optional = $node.Properties.Configuration.Optional.value
    $abbrev = $node.Properties.Configuration.Abbrev
    if ($abbrev -ne "") {""
        $abbrev = " Label=""$abbrev"""
    }
    Add-Content $config -Value "            <Connections Name=""$iname"" AllowMultiple=""False"" Optional=""$optional"" Type=""Connection""$abbrev/>"
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
    Add-Content $config -Value "    <EngineSettings EngineDLL=""Macro"" EngineDLLEntryPoint=""${name}JS/Supporting_Macros/$name.yxmc"" SDKVersion=""10.1""/>"
    Add-Content $config -Value "    <GuiSettings Html=""${name}GUI.html"" Icon=""logo.png"" SDKVersion=""10.1"">"

    $macroInputs =$xmlDoc.AlteryxDocument.Nodes.SelectNodes("Node[GuiSettings/@Plugin='AlteryxBasePluginsGui.MacroInput.MacroInput']")
    $controlParams =$xmlDoc.AlteryxDocument.Nodes.SelectNodes("Node[GuiSettings/@Plugin='AlteryxGuiToolkit.Questions.ControlParam.ControlParam']")
    if ($macroInputs.Count -ne 0 -or $controlParams.Count -ne 0) {
        Add-Content $config -Value '        <InputConnections>'

        if ($controlParams.Count -ne 0) {
            Add-Content $config -Value '            <Connections Name="Control" AllowMultiple="False" Optional="False" Type="Connection" Label="¿"/>'
        }

        foreach ($macroInput in $macroInputs) {
            Add-Connection -node $macroInput -config $config
        }
        Add-Content $config -Value '        </InputConnections>'
    }

    $macroOutputs =$xmlDoc.AlteryxDocument.Nodes.SelectNodes("Node[GuiSettings/@Plugin='AlteryxBasePluginsGui.MacroOutput.MacroOutput']")
    if ($macroOutputs.Count -ne 0) {
        Add-Content $config -Value '        <OutputConnections>'
        foreach ($macroOutput in $macroOutputs) {
            Add-Connection -node $macroOutput -config $config
        }
        Add-Content $config -Value '        </OutputConnections>'
    }

    Add-Content $config -Value '    </GuiSettings>'
    Add-Content $config -Value '    <Properties>'
    Add-Content $config -Value '        <MetaInfo>'
    Add-Content $config -Value "            <Name>${name}JS</Name>"
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

function Write-HTMLFile($macroName, $destination) {
    $content = @'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>[ToolName]</title>
    <script type="text/javascript">
        document.write(`<link rel="import" href="${window.Alteryx.LibDir}2/lib/includes.html">`)
    </script>
</head>
<body>
	<form>
	</form>
    <script type="text/javascript" src="[ToolName]GUI.js"></script>
</body>
</html>
'@
    Set-Content -Path (Join-Path $destination "${macroName}GUI.html") ($content.Replace('[ToolName]', $macroName))
}

function Write-JSFile($macroName, $destination) {
    $content = @'
/**
 * Specify actions that will take place before the tool's configuration is loaded into the manager.
 * @param manager The data manager.
 * @param AlteryxDataItems The data items in use on this page.
 * @param json Configuration
 */
Alteryx.GUI.BeforeLoad = (manager, dataItems, json) => {
}

/**
 * Specify actions that will take place before the tool's configuration is loaded into the manager.
 * @param manager The data manager.
 * @param AlteryxDataItems The data items in use on this page.
 */
Alteryx.GUI.AfterLoad = (manager, AlteryxDataItems) => {
}

/**
 * Reformat the JSON to the style we need
 * @param json Configuration
 */
Alteryx.GUI.BeforeGetConfiguration: (json) =>  {
    return json
}

/**
 * Set the tool's default annotation on the canvas.
 * @param manager The data manager.
 * @returns {string}
 */
Alteryx.GUI.Annotation = (manager) => ""
'@

    Set-Content -Path (Join-Path $destination "${macroName}GUI.js") ($content.Replace('[ToolName]', $macroName))
}

function Write-URLToFIle($uri, $file) {
    Invoke-WebRequest -Uri $uri -Method Head -Verbose
    if (Test-Path $file) {
        Remove-Item -Path $file
    }
    Invoke-WebRequest -Uri $uri -OutFile $file -TimeoutSec 60
}

function Write-Installers($root, $name) {
    Write-URLToFIle https://raw.githubusercontent.com/jdunkerley/AlteryxAddIns/master/Scripts/InstallerHTML.ps1 (Join-Path $root Installer.ps1)
    Set-Content -Path (Join-Path $root "Install.bat") "pushd %~dp0"
    Add-Content -Path (Join-Path $root "Install.bat") "PowerShell -C ""./Installer.ps1 $name"""
    Write-URLToFIle https://raw.githubusercontent.com/jdunkerley/AlteryxAddIns/master/Scripts/UninstallerHTML.ps1 (Join-Path $root Uninstaller.ps1)
    Set-Content -Path (Join-Path $root "Uninstall.bat") "pushd %~dp0"
    Add-Content -Path (Join-Path $root "Uninstall.bat") "PowerShell -C ""./Uninstaller.ps1 $name """
}

if (Test-Path $macroFile) {
    $macroFile = Resolve-Path $macroFile
    $name = (Split-Path $macroFile -Leaf) -replace ".yxmc", ""
    $parent = Split-Path $macroFile -Parent
} else {
    Write-Error "File $macroFile not found."
    exit -1
}

Write-Host "Creating ${name}JS in $targetFolder..."

New-Item -Name "${name}JS" -Path $targetFolder -type directory | Out-Null
$temp = Join-Path $targetFolder "${name}JS"

Write-MacroConfigAndImage -macroFile $macroFile -config (Join-Path $temp "${name}JSConfig.xml")

New-Item -Name 'Supporting_Macros' -Path $temp -type directory | Out-Null
Add-MacroToPackage -macroFile $macroFile -destination (Join-Path $temp 'Supporting_Macros')

Write-HTMLFile $name $temp
Write-JSFile $name $temp
Write-Installers $targetFolder "${name}JS"
