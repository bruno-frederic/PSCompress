---
external help file: PSCompress-help.xml
Module Name: PSCompress
online version: https://github.com/bruno-frederic/PSCompress
schema: 2.0.0
---

# Get-ArchiveInfo

## SYNOPSIS
Affiche le taux de compression et autres informations pour pouvoir trier ensuite.

## SYNTAX

```
Get-ArchiveInfo [-LiteralPath] <String[]> [<CommonParameters>]
```

## DESCRIPTION
ATTENTION : NE MARCHE QUE dans le terminal VS Code "PowerShell Extension" spécifiquement
(manque des assembly dans la console Powershell)

Permet de détecter quels types de fichier il est inutile de recompresser
Anciennement nommée "Get-RARRatio"

## EXAMPLES

### EXEMPLE 1
```
Get-ArchiveInfo 'archive.rar' | ogv
```

Avec OGV on peut ensuite trier, filtrer...

### EXEMPLE 2
```
Get-ArchiveInfo fichier.rar | Where Extension -Eq '.xml' | sort RatioPct
```

Affiche les ratio pour les fichiers XML uniquement

### EXEMPLE 3
```
Get-ArchiveInfo fichier.rar | Group-object -property Extension |
```

Select Name,Count,@{Name="RatioPct"; Expression={$_.Group | Select -Expand RatioPct}}
Rapport complet par extension

### EXEMPLE 4
```
Get-ArchiveInfo fichier.rar | Group-object -property Extension |
```

Select Name,Count,@{Name="RatioPct"; Expression={$_.Group |
        Measure-Object -Property RatioPct -Average | Select -Expand Average}} | sort RatioPct -Desc
Rapport en calculant une moyenne des ratios par extension (la moyenne est faussée car un petit
fichier a la même importance qu'un très gros dans cette manière de calculer)

## PARAMETERS

### -LiteralPath
{{ Fill LiteralPath Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PSPath

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Suite de PSCustomObject. Certaines propriétés sont masquées par défaut.
## NOTES
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

## RELATED LINKS
