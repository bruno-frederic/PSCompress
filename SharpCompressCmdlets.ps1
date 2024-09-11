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
Format supportés par SharpCompress :
https://github.com/adamhathcock/sharpcompress/blob/master/FORMATS.md

TODO : Révérifier ce que supporte SharpCompress comme format 7z par des tests!!!
Il faudrait y accéder via les classes Archive car c’est un format différent, cf note 4
Archive classes allow random access to a seekable stream.

ATTENTION : MARCHE MIEUX dans le terminal VS Code "PowerShell Extension" spécifiquement
(manque des assembly dans la console Powershell qu’il faut rajouter manuellement, ce que j’ai fait
pour certaines verison de SharpCompress)

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

.EXAMPLE
parcours_arbo.py --include *.docx --include *.xlsx | Get-ArchiveInfo | 
    ? { $_.Fullname -Like '*/media/*' -Or $_.Fullname -Like '*/embeddings/*'  -Or $_.Fullname -Like '*/fonts/*'} |
    Select * | OGV
Localise les images et pièces-jointes les plus volumineuses au sein des fichiers Word.

.EXAMPLE
parcours_arbo.py --include *.docx --include *.xlsx | Get-ArchiveInfo | 
    ? { $_.Fullname -Like '*/media/*' -Or $_.Fullname -Like '*/embeddings/*'  -Or $_.Fullname -Like '*/fonts/*'} |
    Group Extension  -NoElement
Rapport sur les types de fichiers inclus dans les DOCX et XLSX

.EXAMPLE
parcours_arbo.py --include *.docx --include *.xlsx | Get-ArchiveInfo | ? CRC -Match '00000000' |
    Select ArchiveName,CRC | OGV
Localise les fichiers xlsx, docx bizarres produits par Google Docs/Takeout

.NOTES
Historique :
    20/03/2021 : correction de la gestion du pipeline
    07/07/2021 : renommé en Get-ArchiveInfo, déplacé dans UtilsCompress et utilise SharpCompress
    16/11/2023 : Mis sous Github, la suite de l’historique dans le log Git…


Utilise la libriaire SharpCompress
Doc     : https://github.com/adamhathcock/sharpcompress/blob/master/USAGE.md
Package : https://www.nuget.org/packages/SharpCompress/

Cette librairie pour fonctionner en dehors de VS Code nécessite de récupérer plusieurs assemblies
dans des versions précises sur Nuget, c’est fastidieux.

J’ai pu faire fonctionner les versions 0.32.2 "net461" puis 0.37.2 "net462" de SharpCompress sous le
terminal VS Code et en dehors en rajoutant les assemblies dans le même dossier que SharpCompress.dll

Pour la v0.37.2 : il faut ajouter l'assembly 'ZstdSharp' v 0.8.0.0 précisément
https://github.com/oleg-st/ZstdSharp/releases
et d’autres assemblies System… pour que ça marche dans une fenêtre windows terminal et pas
uniquement dans VSCode et Powershell Extension :
    system.buffers.4.5.1.nupkg = 4.0.3.0 en net461.zip
    system.memory.4.5.5.nupkg
    system.numerics.vectors.4.5.0.nupkg
    system.runtime.compilerservices.unsafe.4.5.3.nupkg
    system.threading.tasks.extensions.4.5.4.nupkg
    ZstdSharp.Port.0.8.0.nupkg


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
    [string[]]$LiteralPath,

    [Parameter()]
    [string]
    $Password
)

Begin
{
    # Chargement de la librairie .Net dans powershell
    $AssemblyPath = Join-Path -Path $PSScriptRoot -ChildPath 'SharpCompress.dll'
    Import-Module $AssemblyPath


    # Définit les prorpiétés affichées par défaut :
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

        # Propriétés de l’objet de sortie :
        $o = [ordered]@{
            ArchiveName      = $FullName
            Fullname         = $null
            Extension        = $null
            Size             = $null
            CompressedSize   = $null
            RatioPct         = $null
            CRC              = $null
        }
        $filestream = $null
        $reader = $null
        #$reader = ''    # création de la variable pour que le finally puisse la détruire (il me semble que $null posait problême car pas de méthode Dispose)

        try
        {
            $filestream = [System.IO.File]::OpenRead($FullName)

            $opts = New-Object SharpCompress.Readers.ReaderOptions -Property @{
               Password        = $Password
            }

            # Use ReaderFactory to autodetect archive type and Open the entry stream
            $reader = [SharpCompress.Readers.ReaderFactory]::Open($filestream, $opts)

            while ($reader.MoveToNextEntry())
            {
                $o.Fullname         = $null
                $o.Extension        = $null
                $o.Size             = $null
                $o.CompressedSize   = $null
                $o.RatioPct         = $null
                $o.CRC              = $null

                if($reader.Entry.IsDirectory)
                {
                    Write-Verbose "Dossier ignoré : $($reader.Entry.Key)"
                }
                else
                {
                    $o.Fullname         = $reader.Entry.Key
                    $o.Extension        = [System.IO.Path]::GetExtension($reader.Entry.Key)
                    $o.Size             = $reader.Entry.Size
                    $o.CompressedSize   = $reader.Entry.CompressedSize
                    $o.CRC              = $reader.Entry.Crc.ToString('X8')

                    if (0 -ne $reader.Entry.Size)
                    {
                        <# Sur certains fichiers Zip, comme les docx produit par Google Docs/Takeout
                        SharpCompres retourne des Size à 0. Point commun : Ils ont tous
                        "Descriptor UTF8" dans la colonne “Caractéristiques”  visible dans 7-Zip.

                        J’en ai trouvé une vingtaine avec :
                        parcours_arbo.py --include *.docx --include *.xlsx | Get-ArchiveInfo |
                                            ? CRC -Match '00000000' | Select ArchiveName,CRC | OGV

                        Je les ai réenregistrés dans Word avec après une modification mineure.
                        #>
                        $o.RatioPct = [int] [Math]::Floor(100 * $reader.Entry.CompressedSize /
                                                                $reader.Entry.Size)
                    }

                    # Création de l'objet de sortie :
                    $objet_en_sortie = New-Object -TypeName PSObject -Property $o
                    Add-Member -InputObject $objet_en_sortie -MemberType MemberSet `
                                -Name PSStandardMembers -Value $standardMembers
                    Write-Output $objet_en_sortie
                }
            }
        }
        catch [System.Management.Automation.MethodInvocationException]
        {
            if (($FullName -Like '*.docx' -or $FullName -Like '*.xlsx') -and
                'InvalidOperationException' -eq $_.FullyQualifiedErrorId)
            {
                # Ce cas arrive sur les fichiers Office cryptés avec un pass
                # SharpCompress n’arrive pas à ouvrir l’archive
                $o.FullName = "/!\ CRYPTÉ : $FullName ($($_.Exception.InnerException.Message))"

                # Création de l'objet de sortie :
                $objet_en_sortie = New-Object -TypeName PSObject -Property $o
                Add-Member -InputObject $objet_en_sortie -MemberType MemberSet `
                            -Name PSStandardMembers -Value $standardMembers
                Write-Output $objet_en_sortie
            }
            elseif ('CryptographicException' -eq $_.FullyQualifiedErrorId)
            {
                Write-Warning "$Fullname : Déchiffrement impossible ($($_.Exception.InnerException.Message))"
            }
            elseif ('IOException' -eq $_.FullyQualifiedErrorId)
            {
                Write-Warning "$Fullname : Ouverture impossible ($($_.Exception.InnerException.Message))"
            }
            elseif ('TypeInitializationException' -eq $_.FullyQualifiedErrorId)
            {
                Write-RedText "$Fullname : TypeInitializationException se produit quand il manque certaines assembly"
                Write-RedText $_.Exception.InnerException.InnerException.Message
                throw
            }
            else
            {
                Write-RedText $Fullname
                Write-Verbose "rethrow"
                SOE $_
                throw
            }
        }
        catch
        {
            Write-Warning "ATTENTION : NE MARCHE QUE dans le terminal VS Code"
            Write-Warning "(manque des assembly dans la console Powershell)"
            $_ | Write-Warning

            SOE $_
            throw
        }
        finally
        {
            if ($reader)
            {
                $reader.Dispose()
            }
            if ($filestream)
            {
                $filestream.Dispose() # Fermer le fichier pour le dévérouiller Sinon, le RarReader continue de vérouiller le fichier
            }
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
