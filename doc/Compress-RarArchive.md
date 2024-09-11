---
external help file: PSCompress-help.xml
Module Name: PSCompress
online version: https://github.com/bruno-frederic/PSCompress
schema: 2.0.0
---

# Compress-RarArchive

## SYNOPSIS
Equivalent of Compress-Archive cmdlet but calls rar executable to create a .rar archive.

## SYNTAX

```
Compress-RarArchive [-Path] <String[]> [-DestinationPath] <String> [[-CompressionLevel] <String>] [-Update]
 [-Force] [-Password] [-PassThru] [[-Options] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Same arguments as Microsoft's Compress-Archive plus -Password to protect archive
Except -Recurse, this cmdlet Recurse by default.

## EXAMPLES

### EXEMPLE 1
```
Compress-RarArchive -Path * -Destination Archive -CompressionLevel Fastest
```

Compress all the current folder in "Archive.rar", recursively

### EXEMPLE 2
```
gci $env:UserProfile\Documents | Compress-RarArchive -Destination Archive
```

Compress all Documents folder in "Archive.rar", providing filename through pipeline

## PARAMETERS

### -Path
Path or paths to the files to add to the archive.
You can specify multiple paths separated with
commas.
It accepts wildcard characters.
Wildcard characters are expanded by RAR.
(They are not expanded by
Powershell)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PSPath

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DestinationPath
Path to the archive output file.
If DestinationPath doesn't have a .rar file name extension, the
cmdlet adds the .rar file name extension.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CompressionLevel
Specifies the compression to apply:
| CompressionLevel | WinRar equivalence | rar cmdline option |
|------------------|--------------------|--------------------|
| NoCompression    | Store              | -m0                |
| Fastest          | Fastest            | -m1                |
| Optimal          | Best               | -m5                |

Default value : Optimal

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Optimal
Accept pipeline input: False
Accept wildcard characters: False
```

### -Update
Update the existing archive (Actually it is the default mode of Rar)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrite the whole existing archive instead of updating it

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
Protect the archive with a password.
As of 2022, this is still unsupported by Microsoft's cmdlets Compress-Archive and Extract-Archive as
stated here :
- https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/5
- https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/7

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
The cmdlet will output a file object of the archive file created, instead of the output of rar.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Options
Default options provided to rar executable:
|   option    | description
|-------------|-------------------------------------------------------------------------------------
| ma5         | RAR version 5 archive format
| rr5p        | Add data recovery record, 5p→5%
| r           | Recurse subdirectories
| ol          | Save symbolic links as the link instead of the file (requires RAR5)
| ts+         | save all three high precision times
| ep1         | Exclude base dir from names
| id\[c,d,p,q\] | Disable messages, c→copyright string, s→"Done" string, p→percentage indicator

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: -ma5 -rr5p -r -ol -ts+ -ep1 -idcdp
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
### You can pipe a string that contains a Path to one or more files.
## OUTPUTS

### Strings of Rar executable output
### FileInfo
### It returns a FileInfo object if you specify -PassThru
## NOTES

## RELATED LINKS

[https://github.com/bruno-frederic/PSCompress](https://github.com/bruno-frederic/PSCompress)

