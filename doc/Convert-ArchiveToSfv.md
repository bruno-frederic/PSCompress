---
external help file: PSCompress-help.xml
Module Name: PSCompress
online version: https://github.com/bruno-frederic/PSCompress
schema: 2.0.0
---

# Convert-ArchiveToSfv

## SYNOPSIS
Converti des Zip ou Rar en fichier .SFV

## SYNTAX

```
Convert-ArchiveToSfv [-LiteralPath] <String> [<CommonParameters>]
```

## DESCRIPTION
ATTENTION : NE MARCHE QUE dans le terminal VS Code "PowerShell Extension" spécifiquement
(manque des assembly dans la console Powershell)

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -LiteralPath
{{ Fill LiteralPath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: PSPath

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Un chemin d'un fichier
## OUTPUTS

### Les lignes du fichier SFV sortent sur la sortie standard
## NOTES
Pour convertir un .par2 en .MD5 cf.
"Strategie de sauvegarde et d'archivage.docx"

Historique :
    20/03/2021 : Création car c'est trop peu fiable de retraiter la sortie standard de rar avec PS
    07/07/2021 : Conversion en cmdlet et utilise la librairie SharpCompress

## RELATED LINKS
