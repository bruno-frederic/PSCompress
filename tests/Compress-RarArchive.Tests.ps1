<#
.SYNOPSIS
Tests cmdlet Compress-RarArchive, part of PSCompress

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

Describe "Exceptions on bad parameters" {
  BeforeAll {
    # Working on temporary drive :
    Push-Location
    Set-Location TestDrive:

    # Some files required for testing:
    [Byte[]] $rarheader = 0x52,0x61,0x72,0x21,0x1A,0x07,0x01,0x00,0xC1,0xDF,0x5F,0x56,0x03,0x01,
                          0x04,0x00,0x1D,0x77,0x56,0x51,0x03,0x05,0x04,0x00
    Set-Content -Value $rarheader -Encoding byte -Path ExistingArchive.rar

    'Sample content' | Out-File Samplefile.txt
  }

  It 'Unsupported extension' {
    { Compress-RarArchive -DestinationPath Archive.ext -Path . } |
      Should -Throw -ErrorId 'NotSupportedArchiveFileExtension,Compress-RarArchive'
  }

  It 'Can not specify -Force and -Update simultaneously' {
    { Compress-RarArchive -DestinationPath Archive -Path . -Update -Force } |
      Should -Throw -ErrorId 'AmbiguousParameterSet,Compress-RarArchive'
  }

  It 'File already exists' {
    { Compress-RarArchive -DestinationPath ExistingArchive.rar -Path . } |
      Should -Throw -ErrorId 'ArchiveFileExists,Compress-RarArchive'

      $out = Compress-RarArchive -DestinationPath ExistingArchive.rar -Path . -Force | Out-String
      $LASTEXITCODE | Should -Be 0
      $out | Should -Match 'Creating archive .*\.rar'
      $out | Should -Match 'Adding .* OK'
      $out | Should -Match 'Adding data recovery record'

      $out = Compress-RarArchive -DestinationPath ExistingArchive.rar -Path . -Update | Out-String
      $LASTEXITCODE | Should -Be 0
      $out | Should -Match 'Updating archive .*\.rar'
      $out | Should -Match 'Updating .* OK'
      $out | Should -Match 'Adding data recovery record'
  }

  It 'Unknown CompressionLevel' {
    { Compress-RarArchive -DestinationPath Archive -Path . -CompressionLevel Foo } |
      Should -Throw -ErrorId 'ParameterArgumentValidationError,Compress-RarArchive'
  }

  It 'Passthru parameter' {
      $o = Compress-RarArchive -DestinationPath Archive -Path . -PassThru
      $LASTEXITCODE | Should -Be 0
      $o | Should -BeOfType System.IO.FileInfo
      Test-Path -LiteralPath $o | Should -BeTrue
  }

  AfterAll {
    # Getting out of temporary drive
    Pop-Location
  }
}
