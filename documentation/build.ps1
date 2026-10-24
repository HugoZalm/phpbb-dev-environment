[CmdletBinding()]
param(
    [string]$Source = 'installatie.md',
    [string]$ImageTag = 'phpbb-docs-pandoc:3.11',
    [ValidateSet('All', 'Pdf', 'Epub')]
    [string]$Target = 'All'
)

$ErrorActionPreference = 'Stop'

$docs = $PSScriptRoot
# Docker mount alleen de documentatiemap, dus het bronbestand moet daar
# rechtstreeks in staan.
$sourceName = Split-Path -Path $Source -Leaf
if ($sourceName -ne $Source) {
    throw "Geef alleen een bestandsnaam op uit de documentatiemap, geen pad: $Source"
}

$sourcePath = Join-Path $docs $sourceName
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Bronbestand niet gevonden: $sourcePath"
}

$base = [System.IO.Path]::GetFileNameWithoutExtension($sourceName)

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker is niet bereikbaar. Start Docker Desktop en probeer het opnieuw.'
}

# De eerste run downloadt de pandoc/latex-image (ongeveer 1 GB) en bouwt
# daar een kleine afgeleide image bovenop met fvextra voor regelafbreking.
# Dezelfde image wordt voor de PDF en de EPUB gebruikt.
docker build --quiet --tag $ImageTag $docs | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Documentatie-image bouwen mislukt (docker exitcode $LASTEXITCODE)."
}

$commonArgs = @(
    'run', '--rm',
    '--volume', "${docs}:/data",
    '--workdir', '/data',
    $ImageTag
)

$pdfArgs = @(
    $sourceName,
    '--output', "$base.pdf",
    '--pdf-engine=xelatex',
    '--toc',
    '--toc-depth=2',
    '--number-sections',
    '--top-level-division=chapter',
    '-V', 'documentclass=report',
    '-V', 'papersize=a4',
    '-V', 'geometry:margin=2.5cm',
    '-V', 'fontsize=11pt',
    '-V', 'lang=nl',
    '-V', 'babel-lang=dutch',
    '-V', 'linkcolor=blue',
    '-V', 'colorlinks=true',
    '-V', 'titlepage=true',
    '--syntax-highlighting=tango',
    '--include-in-header=pdf-header.tex'
)

$epubArgs = @(
    $sourceName,
    '--output', "$base.epub",
    '--toc',
    '--toc-depth=2',
    '--number-sections',
    '--syntax-highlighting=tango',
    '--epub-title-page=true'
)

if ($Target -in @('All', 'Pdf'))
{
    $dockerArgs = $commonArgs + $pdfArgs

    & docker @dockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "PDF-generatie mislukt (docker exitcode $LASTEXITCODE)."
    }

    $output = Join-Path $docs "$base.pdf"
    if (-not (Test-Path -LiteralPath $output) -or (Get-Item -LiteralPath $output).Length -eq 0) {
        throw "PDF is niet aangemaakt: $output"
    }

    Write-Host "PDF aangemaakt: $output"
}

if ($Target -in @('All', 'Epub'))
{
    $dockerArgs = $commonArgs + $epubArgs

    & docker @dockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "EPUB-generatie mislukt (docker exitcode $LASTEXITCODE)."
    }

    $output = Join-Path $docs "$base.epub"
    if (-not (Test-Path -LiteralPath $output) -or (Get-Item -LiteralPath $output).Length -eq 0) {
        throw "EPUB is niet aangemaakt: $output"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($output)
    try
    {
        $mimetype = $archive.GetEntry('mimetype')
        $container = $archive.GetEntry('META-INF/container.xml')
        if (-not $mimetype -or -not $container)
        {
            throw "EPUB-structuur ongeldig (mimetype of container.xml ontbreekt): $output"
        }

        $reader = New-Object System.IO.StreamReader($mimetype.Open())
        try
        {
            $mimeValue = $reader.ReadToEnd().Trim()
        }
        finally
        {
            $reader.Dispose()
        }

        if ($mimeValue -ne 'application/epub+zip')
        {
            throw "EPUB-mimetype ongeldig: $mimeValue"
        }
    }
    finally
    {
        $archive.Dispose()
    }

    Write-Host "EPUB aangemaakt: $output"
}
