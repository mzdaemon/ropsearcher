<#
.SYNOPSIS
Get-ROPGadGets look for useful the ROP Gadgets. 
.DESCRIPTION
Get-ROPGadGets search for useful rop gagets to help bulding the ROP DEP Bypasss. 
It uses data generated by rp++ and usful GadGets the creator identified.
It will create a file with all the gagets ordered by similar instructions for easy observation.
You need to set the PATH to rp++ binary and provide the dll file to search the ROP Gadget
.PARAMETER dllfile
Provide the dll filename that you want to search for ROP Gadgets.
.PARAMETER ropfile
Provide the filename that will store the ROP Gadgets results.
.Example
.\Get-RopGadgets.ps1 -dllfile .\Configuration.dll -ropfile results.txt

#>

param (
    $dllfile = '',
    $ropfile = ''
)


function Invoke-RP {
    param(
        $dllfile
    )

    $rpbinpath = "C:\rp++\rp-win-x86.exe"

    if (-not (Test-Path $rpbinpath)) {
        Throw ("rp++ binary path doesn't not exist, fix the script with correct path !!!")
    }

    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $rpbinpath
    $startInfo.Arguments = "-r 5 -f $dllfile"
    $startInfo.WorkingDirectory = $PSScriptRoot

    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $false

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    $standardOut = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()

    return $standardOut
}


function Get-ROP {
    param (
        $dllfile,
        $ropfile
    )

    # Delete dummy file
    $dummy = "dummy.txt"
    if (Test-Path $dummy) {
        Remove-Item -Path $dummy -verbose
    }
    # If ropfile already exist, delete
    if (Test-Path $ropfile) {
        Remove-Item -Path $ropfile -verbose
    }

    # Useful Gadgets to construct a ROP.
    $GadGetsRegex = @(": pop edi ;.*ret",": pop ebp ;.*ret",": pop esi ;.*ret",": pop ebx ;.*ret",
    ": pop edx ;.*ret",": pop ecx ;.*ret", ": pop eax ;.*ret", ": sub ecx, eax ;.*ret",": sub ecx, edx ;.*ret",
    ": mov eax, ecx ;.*ret", ": mov ecx, eax ;.*ret",": mov ecx, esi ;.*ret",": mov ecx,  \[eax\] ;.*ret" ,": mov eax,  \[eax\] ;.*ret",
    ": push esp ;.*pop esi.*ret", ": mov eax, edi ;.*ret", ".*add esi, eax ;.*ret", ": add eax, esi ;.*ret", ": add eax, ecx ;.*ret",
    ": mov eax, esi ;.*ret", ": mov  \[eax\], ecx.*ret", ": inc ecx ;.*ret", ": mov edx, eax ;.*ret", 
    ": add ecx, edx ;.*ret", ": inc eax ;.*ret", ": dec eax ;.*ret",": xchg eax, esp.*ret",": xchg esp, eax.*ret", 
    ": xchg eax, ecx.*ret",": xchg ecx, eax.*ret", ": add ecx, esi ;.*ret", ": add ebx, esi ;.*ret",
    ": xchg eax, ebx ;.*ret",": mov ecx,  \[ecx\] ;.*ret",".*mov eax,  \[esi\] ;.*ret",": neg eax ;.*ret",": neg ecx ;.*ret",": push eax ; pop.*ret",
    ": mov eax, dword \[eax\] ;.*ret", ": mov dword \[esi\], eax ;.*ret", ": inc esi ;.*ret", ": sub eax, ecx ;.*ret",
    ": xor eax, eax.*ret", ": xchg eax, ebp.*ret", "mov esp, ebp.*ret", ": mov edx, ebx.*ret", ": push edi.*pop.*ret",
    ": mov eax, ebx.*ret", ": mov  \[esi\], eax.*ret", ": add eax, 0x.* ;.*ret", ".*mov  \[esi\], eax.*ret",
    ": sub eax,  \[esp+.*\] ;.*ret", ": push eax ;.*pop ebx.*ret",".*xchg  \[eax\], edx.*ret", ".*mov  \[esi\], edx.*ret",
    ".*mov ebp, esi.*ret", ": add esp,.*ret", ".*sub eax, ebp ;.*ret", ".*add esi, edx ;.*ret",  ".*add esi, edi ;.*ret",
    ": xchg eax, edi.*ret", ".*mov dword \[eax\], edi ;.*ret",": sub esi, edi ;.*ret", ".*mov dword \[eax\], ecx ;.*ret"
    )

    $ropdata = Invoke-RP -dllfile $dllfile
    $ropdata | Out-File -FilePath dummy.txt

    $header = "*"*35
    $topheader = "*"*87
    foreach ($instr in $GadGetsRegex) {
        Write-Host "Looking for Gadget: $instr"
        Write-Output "$topheader" | Out-File -FilePath $ropfile -Append -Encoding utf8
        Write-Output "$header $instr $header"  | Out-File -FilePath $ropfile -Append -Encoding utf8
        Write-Output "$topheader"  | Out-File -FilePath $ropfile -Append -Encoding utf8
        Get-Content .\dummy.txt | Select-String -Pattern "$instr" -AllMatches | Out-File -FilePath $ropfile -Append -Encoding utf8
        Write-Host "Completed looking Gadget: $instr"
    }
    

    
}

Get-ROP -dllfile $dllfile -ropfile $ropfile