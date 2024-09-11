<#
.SYNOPSIS
Provides cmdlets related to SharpCompress .Net library

.DESCRIPTION
web : https://github.com/bruno-frederic/PSCompress

.NOTES
Copyright © 2022 Bruno FREDERIC

This program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not,
see <https://www.gnu.org/licenses/>.
#>



Set-StrictMode -Version 3

function Get-ArchiveInfo
{
<#
.SYNOPSIS
Affiche le taux de compression et autres informations pour pouvoir trier ensuite.

.DESCRIPTION
ATTENTION : NE MARCHE QUE dans le terminal VS Code "PowerShell Extension" spécifiquement
(manque des assembly dans la console Powershell)

Permet de détecter quels types de fichier il est inutile de recompresser
Anciennement nommée "Get-RARRatio"

.OUTPUTS
Suite de PSCustomObject. Certaines propriétés sont masquées par défaut.

.EXAMPLE
Get-ArchiveInfo 'archive.rar' | ogv
Avec OGV on peut ensuite trier, filtrer...

.EXAMPLE
Get-ArchiveInfo fichier.rar | Where Extension -Eq '.xml' | sort RatioPct
Affiche les ratio pour les fichiers XML uniquement

.EXAMPLE
Get-ArchiveInfo fichier.rar | Group-object -property Extension |
              Select Name,Count,@{Name="RatioPct"; Expression={$_.Group | Select -Expand RatioPct}}
Rapport complet par extension

.EXAMPLE
Get-ArchiveInfo fichier.rar | Group-object -property Extension |
    Select Name,Count,@{Name="RatioPct"; Expression={$_.Group |
        Measure-Object -Property RatioPct -Average | Select -Expand Average}} | sort RatioPct -Desc
Rapport en calculant une moyenne des ratios par extension (la moyenne est faussée car un petit
fichier a la même importance qu'un très gros dans cette manière de calculer)

.NOTES
Historique :
    20/03/2021 : correction de la gestion du pipeline
    07/07/2021 : renommé en Get-ArchiveInfo, déplacé dans UtilsCompress et utilise SharpCompress


Utilise la libriaire SharpCompress
Doc     : https://github.com/adamhathcock/sharpcompress/blob/master/USAGE.md
Package : https://www.nuget.org/packages/SharpCompress/

NB : Utiliser la verison 0.26.0 "net46" sous le terminal VS Code, la seule qui marche.
en effet netstandard2.0 : L'assembly se charge mais déconne à l'utilisation dans VS Code et
                          dans console Powershell
et   netstandard2.1 : L'assembly refuse de se charger, manque l'assembly netstandard, Version=2.1
Et impossible de charger les assemblies des dernières version 0.27 et 0.28 de SharpCompress
    car il manque System.Runtime, Version=5.0.0.0 ou autres.


La librairie SharpCompress permet de récupérer des objet Entry qui ont ces propriétés :
    CompressionType  : Rar
    CompressedSize   : 304
    Size             : 913
    Crc              : 1745272599
    Key              : un dossier\2021053122123063_19817_rtiea_export.log
    LinkTarget       :
    LastModifiedTime : 31/05/2021 22:12:49
    CreatedTime      : 01/06/2021 09:32:07
    LastAccessedTime : 01/06/2021 09:32:07
    ArchivedTime     :
    IsEncrypted      : False
    IsDirectory      : False
    IsSplitAfter     : False
    Attrib           :

    CompressionType  : Rar
    CompressedSize   : 0
    Size             : 0
    Crc              : 0
    Key              : un dossier
    LinkTarget       :
    LastModifiedTime : 01/06/2021 09:32:07
    CreatedTime      : 01/06/2021 09:31:37
    LastAccessedTime : 01/06/2021 09:32:07
    ArchivedTime     :
    IsEncrypted      : False
    IsDirectory      : True
    IsSplitAfter     : False
    Attrib           :
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,
                ValueFromPipelineByPropertyName=$True,
                ValueFromPipeline=$True,
                Position=1)]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType 'Leaf'})]
    [Alias("PSPath")]
    [string[]]$LiteralPath
)

Begin
{
    # Chargement de la librairie .Net dans powershell
    $AssemblyPath = Join-Path -Path $PSScriptRoot -ChildPath 'SharpCompress.dll'
    Import-Module $AssemblyPath


    # Définit les prorpiétés afffichées par défaut :
    $Affiches_par_defaut = @(
        'Fullname'
		'Size',
        'RatioPct',
        'CRC'
    )
    $defaultPropertySet = New-Object Management.Automation.PSPropertySet(
                                                                'DefaultDisplayPropertySet',
                                                                [string[]] $Affiches_par_defaut)
    $standardMembers = [Management.Automation.PSMemberInfo[]]@($defaultPropertySet)
}

Process
{
    ForEach ($literal_path_courant in $LiteralPath)
    {
        [string] $FullName = $ExecutionContext.SessionState.Path.
                                     GetUnresolvedProviderPathFromPSPath($literal_path_courant)
        Write-Verbose $FullName

        try
        {
            $filestream = [System.IO.File]::OpenRead($FullName)
            #TODO a finir
            Write-Host "ici"

<#            $opts = New-Object SharpCompress.Readers.ReaderOptions -Property @{
               LeaveStreamOpen = $True
               #Password        = 'xxxx yyyy xxxx' # Ca marche sur les .zip cryptés mais pas avec les .rar
            }
            $reader = [SharpCompress.Readers.ReaderFactory]::Open($filestream, $opts)
#>
            $reader = [SharpCompress.Readers.ReaderFactory]::Open($filestream)
         #   $reader | Get-Member

            while ($reader.MoveToNextEntry())
            {
                if($reader.Entry.IsDirectory)
                {
                    Write-Verbose "Dossier ignoré : $($reader.Entry.Key)"
                }
                else
                {
                    # Crée l'objet de sortie :
                    $o = [PSCustomObject] @{
                        Fullname         = $reader.Entry.Key
                        Extension        = [System.IO.Path]::GetExtension($reader.Entry.Key)
                        Size             = $reader.Entry.Size
                        CompressedSize   = $reader.Entry.CompressedSize
                        RatioPct         = [int] [Math]::Floor(100 * $reader.Entry.CompressedSize /
                                                                    $reader.Entry.Size)
                        CRC              = $reader.Entry.Crc.ToString('X8')
                    }
                    Add-Member -InputObject $o -MemberType MemberSet -Name PSStandardMembers `
                                                                    -Value $standardMembers
                    Write-Output $o
                }
            }
        }
        catch
        {
            Write-Warning "ATTENTION : NE MARCHE QUE dans le terminal VS Code"
            Write-Warning "(manque des assembly dans la console Powershell)"
            $_ | Write-Warning
        }
        finally
        {
      <#      if ($reader)
            {
                $reader.Dispose()
            }
            if ($filestream)
            {
                $filestream.Dispose() # Fermer le fichier pour le dévérouiller Sinon, le RarReader continue de vérouiller le fichier
            }
        #>
        }
    } # ForEach
} # Process
}


function Convert-ArchiveToSfv
{
<#
.SYNOPSIS
Converti des Zip ou Rar en fichier .SFV

.DESCRIPTION
ATTENTION : NE MARCHE QUE dans le terminal VS Code "PowerShell Extension" spécifiquement
(manque des assembly dans la console Powershell)

.INPUTS
Un chemin d'un fichier

.OUTPUTS
Les lignes du fichier SFV sortent sur la sortie standard

.NOTES
Pour convertir un .par2 en .MD5 cf. "Strategie de sauvegarde et d'archivage.docx"

Historique :
    20/03/2021 : Création car c'est trop peu fiable de retraiter la sortie standard de rar avec PS
    07/07/2021 : Conversion en cmdlet et utilise la librairie SharpCompress
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,
                ValueFromPipelineByPropertyName=$False,
                ValueFromPipeline=$False,
                Position=1)]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType 'Leaf'})]
    [Alias("PSPath")]
    [string]$LiteralPath
)

    Get-ArchiveInfo $LiteralPath | ForEach-Object { '{0}        {1:X8}' -f $_.Fullname,$_.Crc }
}
