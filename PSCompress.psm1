<#
.SYNOPSIS
PSCompress module provides advanced archive compression and uncompression cmdlets to Powershell

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

# Includes SharpCompress related cmdlets:
. "$PSScriptRoot\SharpCompressCmdlets.ps1"

function Compress-RarArchive
{
<#
.SYNOPSIS
Equivalent of Compress-Archive cmdlet but calls rar executable to create a .rar archive.

.DESCRIPTION
Same arguments as Microsoft's Compress-Archive plus -Password to protect archive
Except -Recurse, this cmdlet Recurse by default.

.EXAMPLE
Compress-RarArchive -Path * -Destination Archive -CompressionLevel Fastest
Compress all the current folder in "Archive.rar", recursively

.EXAMPLE
gci $env:UserProfile\Documents | Compress-RarArchive -Destination Archive
Compress all Documents folder in "Archive.rar", providing filename through pipeline

.PARAMETER Path
Path or paths to the files to add to the archive. You can specify multiple paths separated with
commas.
It accepts wildcard characters. Wildcard characters are expanded by RAR. (They are not expanded by
Powershell)

.PARAMETER DestinationPath
Path to the archive output file. If DestinationPath doesn't have a .rar file name extension, the
cmdlet adds the .rar file name extension.

.PARAMETER Force
Overwrite the whole existing archive instead of updating it

.PARAMETER Update
Update the existing archive (Actually it is the default mode of Rar)

.PARAMETER CompressionLevel
Specifies the compression to apply:
| CompressionLevel | WinRar equivalence | rar cmdline option |
|------------------|--------------------|--------------------|
| NoCompression    | Store              | -m0                |
| Fastest          | Fastest            | -m1                |
| Optimal          | Best               | -m5                |

Default value : Optimal


.PARAMETER Password
Protect the archive with a password.
As of 2022, this is still unsupported by Microsoft's cmdlets Compress-Archive and Extract-Archive as
stated here :
- https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/5
- https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/7

.PARAMETER PassThru
The cmdlet will output a file object of the archive file created, instead of the output of rar.

.INPUTS
String
You can pipe a string that contains a Path to one or more files.

.OUTPUTS
Strings of Rar executable output

FileInfo
It returns a FileInfo object if you specify -PassThru

.LINK
https://github.com/bruno-frederic/PSCompress
#>

[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact="Medium")]
param (
    [Parameter(Mandatory=$True,
               ValueFromPipelineByPropertyName=$True,
               ValueFromPipeline=$True)]
    [ValidateScript({Test-Path -Path $_ })]
    [Alias("PSPath")]
    [string[]]$Path,

    [Parameter(Mandatory=$True)]
    [string]$DestinationPath,

    [Parameter()]
    [string]
    $CompressionLevel = 'Optimal',

    [Parameter()]
    [switch]
    $Update,

    [Parameter()]
    [switch]
    $Force,

    [Parameter()]
    [switch]
    $Password,

    [Parameter()]
    [switch]
    $PassThru,

    [Parameter()]
    [string]
    $Options = '-ma5 -rr5p -r -ol -ts+ -ep1 -idcdp'
<# Default options provided to rar executable:
|   option    | description
|-------------|-------------------------------------------------------------------------------------
| ma5         | RAR version 5 archive format
| rr5p        | Add data recovery record, 5p→5%
| r           | Recurse subdirectories
| ol          | Save symbolic links as the link instead of the file (requires RAR5)
| ts+         | save all three high precision times
| ep1         | Exclude base dir from names
| id[c,d,p,q] | Disable messages, c→copyright string, s→"Done" string, p→percentage indicator
#>
)

    Begin
    {
        # Normalisation of DestinationPath so that extension is always include:
        $s = [IO.Path]::GetExtension($DestinationPath)
        switch ($s) {
            ''     { $DestinationPath += '.rar' }
            '.rar' {  }
            '.bkp' {  }
            # Same Exception as the Compress-archive cmdlet:
            Default {
                $Exception = New-Object System.IO.IOException(
                    "$($MyInvocation.MyCommand) : $s is not a supported archive file format. .rar "+
                    " is the only supported archive file format.")

                throw New-Object System.Management.Automation.ErrorRecord(
                        $Exception,
                        "NotSupportedArchiveFileExtension,$($MyInvocation.MyCommand)",     # errorId
                        [Management.Automation.ErrorCategory]::InvalidArgument,      # ErrorCategory
                        $s)
            }
        }

        if ($Update)
        {
            if ($Force)
            {
                $Exception = New-Object System.Management.Automation.ParameterBindingException(
                        "$($MyInvocation.MyCommand) : Can not specify -Force and -Update " +
                        "simultaneously")

                throw New-Object System.Management.Automation.ErrorRecord(
                        $Exception,
                        "AmbiguousParameterSet,$($MyInvocation.MyCommand)",      # errorId
                        [Management.Automation.ErrorCategory]::InvalidArgument,  # ErrorCategory
                        $Null)
            }
        }
        else
        {
            if (Test-Path -LiteralPath $DestinationPath)
            {
                if ($Force)
                {
                    Remove-Item $DestinationPath
                }
                else
                {
                    $Exception = New-Object System.IO.IOException(
                            "$($MyInvocation.MyCommand) : The archive file $DestinationPath " +
                            "already exists. Use the -Update parameter to update  the existing " +
                            "archive file or use the -Force parameter to overwrite the existing " +
                            "archive file.")

                    throw New-Object System.Management.Automation.ErrorRecord(
                            $Exception,
                            "ArchiveFileExists,$($MyInvocation.MyCommand)",          # errorId
                            [Management.Automation.ErrorCategory]::InvalidArgument,  # ErrorCategory
                            $DestinationPath)                                        # targetObject
                }
            }
        }

        # Map CompressionLevel to rar option:
        switch ($CompressionLevel) {
            'Optimal'       { $CompressionLevel = '-m5' }
            'NoCompression' { $CompressionLevel = '-m0' }
            'Fastest'       { $CompressionLevel = '-m1' }
            Default {
                $Exception = New-Object System.Management.Automation.ParameterBindingException (
                        "$($MyInvocation.MyCommand) : Unknown CompressionLevel!")

                throw New-Object System.Management.Automation.ErrorRecord(
                        $Exception,
                        "ParameterArgumentValidationError,$($MyInvocation.MyCommand)", # errorId
                        [Management.Automation.ErrorCategory]::InvalidData,      # ErrorCategory
                        $Null)
            }
        }

        # To support objects coming from pipeline, one by one, we store all theses objects in this
        # array and launch Rar in the End{} block:
        [string[]] $liste = @()
    }

    Process
    {
      ForEach ($cur in $Path)
      {
          # This does NOT expand wildcards:
          $liste += $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($cur)
      }
    }

    End
    {
        # Temporary list of file is generated:
        $tmp = New-TemporaryFile
        $listfilepath = $tmp.FullName + $MyInvocation.MyCommand + '.txt'
        Out-File -InputObject $liste -Encoding utf8 -LiteralPath $listfilepath

        # Launching RAR executable:
        if ($Password) { $Options += ' -hp' }
        $out = 'Write-Output'
        if ($PassThru) { $out = 'Write-Verbose' }

        $cmd = "rar a $CompressionLevel $Options -scFl '$DestinationPath' ``@'$listfilepath' | $out"
        # -scFl → the file list is expected to be UTF-8 formatted
        [Int32] $ExitCodeRar = 0
        if ($PSCmdlet.ShouldProcess("Lancement : $cmd"))
        {
            Invoke-Expression $cmd
            $ExitCodeRar = $lastexitcode
        }

        Remove-Item $listfilepath,$tmp

        Write-Verbose "ExitCode Rar = $ExitCodeRar"
        switch ( $ExitCodeRar )
        {
            0       { Write-Verbose "Successful operation"                                }
            1       { Write-Warning "Non fatal error(s) occurred."                        }
            255     { Write-Warning "User stopped the process."                           }
            default { Write-Warning "Error code $ExitcodeRar, cf. Rar.txt, § Exit values" }
            # A more precise exitcode mangament would only be useful if I disable RAR standar output
        }

        if ($PassThru)
        {
            Get-Item -LiteralPath $DestinationPath
        }
    }
}
