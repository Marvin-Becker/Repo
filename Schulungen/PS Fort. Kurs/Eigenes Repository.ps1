Freigabebasiertes PowerShell-Repository


Auf RepositoryServer:

Share erstellen: Jeder Lesen
\\PW16A\Repo



Register-PSRepository -Name MyRepo -SourceLocation \\PW16A\Repo

New-ModuleManifest -Path C:\MeinModul\MeinModul.psd1 -Author Thomas -RootModule C:\MeinModul\MeinModul.psm1 -Description "Test"

Publish-Module -Path C:\MeinModul -Repository Myrepo




Find-Command -Repository Myrepo

Install-Module meinmodul -Repository myrepo



https://docs.microsoft.com/de-de/nuget/hosting-packages/nuget-server


