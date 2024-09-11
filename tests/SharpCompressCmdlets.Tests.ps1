<#
.SYNOPSIS
Tests Sharp Comrpess cmdlets, part of PSCompress

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

Describe "Encrypted archives" {
  BeforeAll {
    # Working on temporary drive :
    Push-Location
    Set-Location TestDrive:

    $Samplefile = 'Samplefile.txt'
    'Sample content' | Out-File $Samplefile
    $CRC32 = get-Filecrc32 -LiteralPath $Samplefile| Select-Object -Expand Hash
  }

  It 'ZipCrypto' {
    Remove-Item Archive.*
    cmd /c start /wait d:\utils\winrar\WinRAR a -s -psomepas -mezl Archive.zip $Samplefile
    $o = Get-ArchiveInfo -Password somepas -LiteralPath Archive.zip

    $o.Fullname | Should -Be $Samplefile
    $o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It 'Zip AES-256' {
    Remove-Item Archive.*
    cmd /c start /wait d:\utils\winrar\WinRAR a -s -psomepas Archive.zip $Samplefile
    $o = Get-ArchiveInfo -Password somepas -LiteralPath Archive.zip

    Write-Host $o
    $o.Fullname | Should -Be $Samplefile
    # FIXME : Get-ArchiveInfo retourne un CRC 00000000
    #$o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }


  It 'RAR Encrypted' {
    Remove-Item Archive.*
    rar a -psomepas Archive.rar $Samplefile
    $o = Get-ArchiveInfo -Password somepas -LiteralPath Archive.rar

    Write-Host $o
    $o.Fullname | Should -Be $Samplefile
    # FIXME : Get-ArchiveInfo retourne un CRC aléatoire incorrect. Probablement un bug SharpCompress
    #$o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It 'RAR filenames Encrypted' {
    Remove-Item Archive.*
    rar a -hpsomepas Archive.rar $Samplefile
    $o = Get-ArchiveInfo -Password somepas -LiteralPath Archive.rar

    $o.Fullname | Should -Be $Samplefile
    $o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    # Getting out of temporary drive
    Pop-Location
  }
}
