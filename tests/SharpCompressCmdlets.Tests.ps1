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

    $Pass = 'P@ssw0rd'
    $SecurePass = ConvertTo-SecureString -String $Pass -AsPlainText -Force

    $Samplefile = 'Samplefile.txt'
    'Sample content' | Out-File $Samplefile
    $Size = Get-Item $Samplefile | Select-Object -expand Length
    $CRC32 = get-Filecrc32 -LiteralPath $Samplefile| Select-Object -Expand Hash
  }

  It 'ZipCrypto' {
    Remove-Item Archive.*
    Start-Process -Wait -FilePath d:\utils\winrar\WinRAR `
              -ArgumentList "a -ibck -p'$Pass' -mezl Archive.zip $Samplefile"
    $o = Get-ArchiveInfo -Password $SecurePass -LiteralPath Archive.zip

    $o.Fullname | Should -Be $Samplefile
    $o.Size     | Should -Be $Size
    $o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It 'Zip AES-256' {
    Remove-Item Archive.*
    Start-Process -Wait -FilePath d:\utils\winrar\WinRAR `
              -ArgumentList "a -ibck -p'$Pass' Archive.zip $Samplefile"
    $o = Get-ArchiveInfo -Password $SecurePass -LiteralPath Archive.zip

    $o.Fullname | Should -Be $Samplefile
    $o.Size     | Should -Be $Size
    Write-Host "$o : " -NoNewline
    Write-Host "SharpCompress retourne un CRC 00000000, tout comme 7z : " -NoNewline
    7z l -slt -p"$Pass" Archive.zip | Select-String CRC.= | Write-Host

    #$o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It '7z Encrypted' {
    Remove-Item Archive.*
    7z a -p"$Pass"     Archive.7z $Samplefile
    $o = Get-ArchiveInfo -Password $SecurePass -LiteralPath Archive.7z

    $o.Fullname | Should -Be $Samplefile
    $o.Size     | Should -Be $Size
    $o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It '7z filenames Encrypted' {
    Remove-Item Archive.*
    7z a -p"$Pass" -mhe Archive.7z $Samplefile
    $o = Get-ArchiveInfo -Password $SecurePass -LiteralPath Archive.7z

    $o.Fullname | Should -Be $Samplefile
    $o.Size     | Should -Be $Size
    $o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It 'RAR Encrypted' {
    Remove-Item Archive.*
    rar a -p"$Pass" Archive.rar $Samplefile
    $o = Get-ArchiveInfo -Password $SecurePass -LiteralPath Archive.rar

    $o.Fullname | Should -Be $Samplefile
    $o.Size     | Should -Be $Size
    Write-Host "$o : " -NoNewline
    Write-Host "SharpCompress retourne un CRC incorrect, le même que WinRar et Rar :" -NoNewline
    # Cela me parait plus robuste qu’on ne connaisse pas le CRC d’un fichier chiffré pour ne pas
    # aider au déchiffrement.
    rar lt -p"$Pass" Archive.rar | Select-String CRC32 | Write-Host
    Write-Host "Tandis que 7z retourne un CRC vide : " -NoNewline
    7z l -slt -p"$Pass" Archive.rar | Select-String CRC.= | Write-Host

    #$o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  It 'RAR filenames Encrypted' {
    Remove-Item Archive.*
    rar a -hp"$Pass" Archive.rar $Samplefile
    $o = Get-ArchiveInfo -Password $SecurePass -LiteralPath Archive.rar

    $o.Fullname | Should -Be $Samplefile
    $o.Size     | Should -Be $Size
    $o.CRC      | Should -Be $CRC32
    $LASTEXITCODE | Should -Be 0
  }

  AfterAll {
    # Getting out of temporary drive
    Pop-Location
  }
}
