# nur mal zum Anschauen:
gcm get-service| select @{N="Path";E={Join-Path $pshome\en-us $_.helpfile}} |get-content -Head 30


# Eigene externe Hilfe erstellen

Install-Module platyps

sl # in den Modulpfad wechseln

New-ModuleManifest -Path .\MeinModul.psd1 -Author Thomas -RootModule "C:\Program Files\WindowsPowerShell\Modules\MeinModul\MeinModul.psm1" -Description "Test"

md docs

New-MarkdownHelp -Module MeinModul -OutputFolder .\docs\ -WithModulePage

.md-Datei editieren # (".md" ist eine Textdatei - notfalls mit Notepad oder in Visual Studio integrieren)

md de-de

New-ExternalHelp -Path .\docs\ -OutputPath .\de-de\ -Force

Get-HelpPreview .\de-de\MeinModul-help.xml

# oder gleich:   help Cmdlet -full


https://docs.microsoft.com/de-de/powershell/scripting/dev-cross-plat/create-help-using-platyps?view=powershell-7.1

# Tool zum umwandeln in HTML:
https://pandoc.org/