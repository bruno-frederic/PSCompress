# PSCompress
PSCompress module provides advanced archive compression and uncompression cmdlets to Powershell


# Available cmdlets
- [Compress-RarArchive](doc/Compress-RarArchive.md) : Equivalent of Microsoft's Compress-Archive
cmdlet but calls `rar` executable to create a `.rar` archive.
### Requirements
- Rar command-line executable in the *PATH* environment</BR>
  Executable available here : https://www.rarlab.com/

# Experimental cmdlets
⚠ Bug occurs on some archives with these cmdlets using SharpCompress .net library ...

- [Get-ArchiveInfo](doc/Get-ArchiveInfo.md) : Display compression ratio and technical informations
about the content of an archive.
- [Convert-ArchiveToSfv](doc/Convert-ArchiveToSfv.md) : Generates a `.sfv` checksums file from files
inside Zip or Rar archives

### Requirements for these experimental cmdlets
- SharpCompress .net library. Package is available here : https://www.nuget.org/packages/SharpCompress/ <br/>
Put the `lib/net461/SharpCompress.dll` file in the same directory as PS-Compress.psm1

As of today, version 0.32.2.0 of SharpCompress requires also:
* System.Memory package with the exact version number 4.0.1.1 available in this v**4.5.4** nugget
package:
https://www.nuget.org/api/v2/package/System.Memory/4.5.4 <br/>
Put the `lib/net461/System.Memory.dll` file in the same directory as PS-Compress.psm1

- System.Buffers: https://www.nuget.org/api/v2/package/System.Buffers/4.5.1 <br/>
Put the `lib/net461/System.Buffers.dll` file in the same directory as PS-Compress.psm1


# LICENSE
Copyright © 2022 Bruno FREDERIC

This program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not,
see <https://www.gnu.org/licenses/>.