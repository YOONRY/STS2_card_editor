$ErrorActionPreference = 'Stop'

$metadataDll = 'C:\Program Files\dotnet\sdk\8.0.202\Sdks\Microsoft.NET.Sdk\tools\net472\System.Reflection.Metadata.dll'
$immutableDll = 'C:\Program Files\dotnet\sdk\8.0.202\Sdks\Microsoft.NET.Sdk\tools\net472\System.Collections.Immutable.dll'

Add-Type -Path $immutableDll
Add-Type -Path $metadataDll

$singleByteOpcodes = @{}
$doubleByteOpcodes = @{}

[System.Reflection.Emit.OpCodes].GetFields([System.Reflection.BindingFlags]'Public,Static') | ForEach-Object {
    $opcode = $_.GetValue($null)
    $value = ([int]$opcode.Value) -band 0xFFFF
    if (($value -band 0xFF00) -eq 0xFE00) {
        $doubleByteOpcodes[$value -band 0xFF] = $opcode
    } else {
        $singleByteOpcodes[$value] = $opcode
    }
}

function Get-OperandSize {
    param(
        [byte[]]$Bytes,
        [int]$Offset,
        [System.Reflection.Emit.OperandType]$OperandType
    )

    switch ($OperandType.ToString()) {
        'InlineNone' { return 0 }
        'ShortInlineBrTarget' { return 1 }
        'ShortInlineI' { return 1 }
        'ShortInlineVar' { return 1 }
        'InlineVar' { return 2 }
        'InlineI' { return 4 }
        'InlineBrTarget' { return 4 }
        'InlineField' { return 4 }
        'InlineMethod' { return 4 }
        'InlineSig' { return 4 }
        'InlineString' { return 4 }
        'InlineTok' { return 4 }
        'InlineType' { return 4 }
        'InlineI8' { return 8 }
        'InlineR' { return 8 }
        'ShortInlineR' { return 4 }
        'InlineSwitch' {
            $count = [BitConverter]::ToInt32($Bytes, $Offset)
            return 4 + (4 * $count)
        }
        default {
            throw "Unknown operand type: $OperandType"
        }
    }
}

function Resolve-MetadataToken {
    param(
        $Reader,
        [int]$Token
    )

    $handle = [System.Reflection.Metadata.Ecma335.MetadataTokens]::Handle($Token)
    $kind = $handle.Kind.ToString()

    switch ($kind) {
        'UserString' {
            return 'UserString: ' + $Reader.GetUserString([System.Reflection.Metadata.UserStringHandle]$handle)
        }
        'TypeDefinition' {
            $typeDef = $Reader.GetTypeDefinition([System.Reflection.Metadata.TypeDefinitionHandle]$handle)
            return 'TypeDef: ' + $Reader.GetString($typeDef.Namespace) + '.' + $Reader.GetString($typeDef.Name)
        }
        'TypeReference' {
            $typeRef = $Reader.GetTypeReference([System.Reflection.Metadata.TypeReferenceHandle]$handle)
            return 'TypeRef: ' + $Reader.GetString($typeRef.Namespace) + '.' + $Reader.GetString($typeRef.Name)
        }
        'MethodDefinition' {
            $methodDef = $Reader.GetMethodDefinition([System.Reflection.Metadata.MethodDefinitionHandle]$handle)
            return 'MethodDef: ' + $Reader.GetString($methodDef.Name)
        }
        'MemberReference' {
            $memberRef = $Reader.GetMemberReference([System.Reflection.Metadata.MemberReferenceHandle]$handle)
            return 'MemberRef: ' + $Reader.GetString($memberRef.Name)
        }
        'FieldDefinition' {
            $fieldDef = $Reader.GetFieldDefinition([System.Reflection.Metadata.FieldDefinitionHandle]$handle)
            return 'FieldDef: ' + $Reader.GetString($fieldDef.Name)
        }
        'TypeSpecification' {
            return 'TypeSpec'
        }
        'MethodSpecification' {
            return 'MethodSpec'
        }
        'StandaloneSignature' {
            return 'StandaloneSignature'
        }
        default {
            return $kind + ':0x' + ('{0:X8}' -f $Token)
        }
    }
}

function Show-MethodIl {
    param(
        [string]$AssemblyPath,
        [string]$TargetNamespace,
        [string]$TargetTypeName,
        [string]$MethodName
    )

    $stream = [System.IO.File]::OpenRead($AssemblyPath)
    try {
        $peReader = [System.Reflection.PortableExecutable.PEReader]::new($stream)
        $provider = [System.Reflection.Metadata.MetadataReaderProvider]::FromMetadataImage($peReader.GetMetadata().GetContent())
        try {
            $reader = $provider.GetMetadataReader()
            foreach ($typeHandle in $reader.TypeDefinitions) {
                $typeDef = $reader.GetTypeDefinition($typeHandle)
                $namespace = $reader.GetString($typeDef.Namespace)
                $typeName = $reader.GetString($typeDef.Name)
                if ($namespace -ne $TargetNamespace -or $typeName -ne $TargetTypeName) {
                    continue
                }

                foreach ($methodHandle in $typeDef.GetMethods()) {
                    $methodDef = $reader.GetMethodDefinition($methodHandle)
                    $currentMethodName = $reader.GetString($methodDef.Name)
                    if ($currentMethodName -ne $MethodName) {
                        continue
                    }

                    "METHOD $namespace.$typeName::$currentMethodName"
                    $sectionData = $peReader.GetSectionData($methodDef.RelativeVirtualAddress)
                    $body = [System.Reflection.Metadata.MethodBodyBlock]::Create($sectionData.GetReader())
                    $bytes = $body.GetILBytes()
                    $offset = 0
                    while ($offset -lt $bytes.Length) {
                        $instructionOffset = $offset
                        $opcodeByte = $bytes[$offset]
                        $offset += 1

                        if ($opcodeByte -eq 0xFE) {
                            $opcode = $doubleByteOpcodes[[int]$bytes[$offset]]
                            $offset += 1
                        } else {
                            $opcode = $singleByteOpcodes[[int]$opcodeByte]
                        }

                        if (-not $opcode) {
                            '{0:X4}: <unknown opcode 0x{1:X2}>' -f $instructionOffset, $opcodeByte
                            break
                        }

                        $operandSize = Get-OperandSize -Bytes $bytes -Offset $offset -OperandType $opcode.OperandType
                        $operandText = ''
                        switch ($opcode.OperandType.ToString()) {
                            'InlineString' {
                                $token = [BitConverter]::ToInt32($bytes, $offset)
                                $operandText = ' -> ' + (Resolve-MetadataToken -Reader $reader -Token $token)
                            }
                            'InlineField' {
                                $token = [BitConverter]::ToInt32($bytes, $offset)
                                $operandText = ' -> ' + (Resolve-MetadataToken -Reader $reader -Token $token)
                            }
                            'InlineMethod' {
                                $token = [BitConverter]::ToInt32($bytes, $offset)
                                $operandText = ' -> ' + (Resolve-MetadataToken -Reader $reader -Token $token)
                            }
                            'InlineTok' {
                                $token = [BitConverter]::ToInt32($bytes, $offset)
                                $operandText = ' -> ' + (Resolve-MetadataToken -Reader $reader -Token $token)
                            }
                            'InlineType' {
                                $token = [BitConverter]::ToInt32($bytes, $offset)
                                $operandText = ' -> ' + (Resolve-MetadataToken -Reader $reader -Token $token)
                            }
                            'InlineI' {
                                $operandText = ' -> ' + [BitConverter]::ToInt32($bytes, $offset)
                            }
                            'ShortInlineI' {
                                $operandText = ' -> ' + [int][sbyte]$bytes[$offset]
                            }
                            'InlineSwitch' {
                                $count = [BitConverter]::ToInt32($bytes, $offset)
                                $operandText = " -> switch($count)"
                            }
                        }

                        '{0:X4}: {1}{2}' -f $instructionOffset, $opcode.Name, $operandText
                        $offset += $operandSize
                    }
                    return
                }
            }

            throw "Method not found: $TargetNamespace.$TargetTypeName::$MethodName"
        } finally {
            $provider.Dispose()
        }
    } finally {
        if ($peReader) {
            $peReader.Dispose()
        }
        $stream.Dispose()
    }
}

$installDir = if ($env:SLAY_THE_SPIRE_2_DIR) { $env:SLAY_THE_SPIRE_2_DIR } else { 'C:\Program Files (x86)\Steam\steamapps\common\Slay the Spire 2' }
$assembly = Join-Path $installDir 'data_sts2_windows_x86_64\sts2.dll'
if (-not (Test-Path $assembly)) {
    throw "sts2.dll not found at '$assembly'. Set SLAY_THE_SPIRE_2_DIR to your game install folder."
}

Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'ReadModsInDirRecursive'
''
Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'Initialize'
''
Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'ReadModManifest'
''
Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'ReadSteamMods'
''
Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'TryReadModFromSteam'
''
Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'TryLoadMod'
''
Show-MethodIl -AssemblyPath $assembly -TargetNamespace 'MegaCrit.Sts2.Core.Modding' -TargetTypeName 'ModManager' -MethodName 'CallModInitializer'
