# spool_progress_v2.json 자동 실행 + Excel 보고서 매크로(Ribbon_RunOne) 실행
#
# 흐름:
#   1. SHIIS 잔존 프로세스 정리
#   2. erpctrl run --scenario scenarios/spool_progress_v2.json --vars "..."
#   3. 종료 코드 확인 (0=passed)
#   4. Excel 보고서 파일 열기 (${SaveDir}\r_${WoNo}-SPOOL PROGRESS REPORT.xlsx)
#   5. xlam add-in의 Ribbon_RunOne 매크로 호출
#   6. Save + Close + Excel Quit
#
# 사용:
#   pwsh tools/run_spool_progress.ps1 `
#       -WoNo P250129-01 `
#       -SaveDir "D:\tmp" `
#       -UserId S20190101 `
#       -Pwd 1234 `
#       -SherpExePath "C:\Seonghwa\SHIIS3\shERP.exe"
#
#   환경변수로 주입 가능 (param 생략 시 env에서 자동 사용)

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$WoNo,
    [string]$SaveDir       = $env:SAVE_DIR,
    [string]$UserId        = $env:USER_ID,
    [string]$Pwd           = $env:PWD,
    [string]$SherpExePath  = $env:SHERP_EXE_PATH,
    [string]$ErpctrlExe,
    [string]$ScenarioPath,
    [string]$ReportPrefix  = "",
    [string]$ReportSuffix  = "SPOOL PROGRESS REPORT_TMPL.xlsx",
    [string]$MacroName     = "'Smart Excel.xlam'!User_Design_Run",
    [string]$OutputPrefix  = "SPOOL PROGRESS REPORT",
    [string]$AddinXlamPath,   # xlam 절대경로 (옵션) — 지정 시 명시적으로 Workbooks.Open으로 로드
    [string]$AddinName,
    [int]$MacroRetryCount = 1,
    [int]$MacroRetryDelaySec = 10,
    [switch]$ReloadAllAddins,
    [switch]$ShowExcelAlerts,
    [switch]$KeepExcelOpen,
    [switch]$SkipErpctrl,
    [switch]$AllowEmptyOrderStatus = $true,
    [switch]$NoCleanup,
    [switch]$NoUpdate,
    [string]$LogDir   # override (default: 공유서버 → 공유받은 폴더 → %LOCALAPPDATA% 순으로 fallback)
)

$ErrorActionPreference = "Stop"

try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($PSCommandPath) {
    Split-Path -Parent $PSCommandPath
} else {
    (Get-Location).Path
}

if (-not $ErpctrlExe) {
    $ErpctrlExe = Join-Path $ScriptDir "ErpCtrl\erpctrl.exe"
}
if (-not $ScenarioPath) {
    $ScenarioPath = Join-Path $ScriptDir "ErpCtrl\scenarios\spool_progress_v2.json"
}

function Release-ComObjectQuietly {
    param([object]$ComObject)
    if ($null -ne $ComObject) {
        try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ComObject) | Out-Null } catch { }
    }
}

function Get-MacroWorkbookName {
    param([string]$Name)
    if (-not $Name -or -not $Name.Contains("!")) { return $null }
    return ($Name.Split("!", 2)[0]).Trim("'").Trim('"')
}

function Wait-ExcelReady {
    param(
        [Parameter(Mandatory=$true)] [object]$Excel,
        [int]$TimeoutSec = 60
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            if ($Excel.Ready) { return $true }
        } catch {
            return $false
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Warning "Excel Ready 대기 시간 초과 (${TimeoutSec}s). 다음 단계 진행."
    return $false
}

function Load-ExcelAddins {
    param(
        [Parameter(Mandatory=$true)] [object]$Excel,
        [string]$MacroName,
        [string]$AddinName,
        [string]$AddinXlamPath,
        [switch]$ReloadAllAddins
    )

    if ($ReloadAllAddins) {
        Write-Host "==> Excel Add-in 강제 로드 (등록된 모든 추가기능)"
        foreach ($addin in $Excel.AddIns) {
            if ($addin.Installed) {
                try {
                    $addin.Installed = $false
                    Start-Sleep -Milliseconds 300
                    $addin.Installed = $true
                    Write-Host "    add-in reloaded: $($addin.Name)"
                } catch {
                    Write-Warning "    add-in toggle failed: $($addin.Name) — $($_.Exception.Message)"
                }
            }
        }
    } else {
        $targetAddinName = $AddinName
        if (-not $targetAddinName) { $targetAddinName = Get-MacroWorkbookName $MacroName }
        if ($targetAddinName) {
            Write-Host "==> Excel Add-in 로드: $targetAddinName"
            $found = $false
            foreach ($addin in $Excel.AddIns) {
                if ($addin.Name -ieq $targetAddinName) {
                    $found = $true
                    try {
                        $addin.Installed = $false
                        Start-Sleep -Milliseconds 300
                        $addin.Installed = $true
                        Write-Host "    add-in reloaded: $($addin.Name)"
                    } catch {
                        Write-Warning "    add-in toggle failed: $($addin.Name) — $($_.Exception.Message)"
                    }
                    break
                }
            }
            if (-not $found) {
                Write-Warning "등록된 Excel Add-in에서 찾지 못함: $targetAddinName"
            }
        }
    }

    if ($AddinXlamPath -and (Test-Path $AddinXlamPath)) {
        Write-Host "==> xlam 명시 로드: $AddinXlamPath"
        $Excel.Workbooks.Open($AddinXlamPath) | Out-Null
    } elseif ($AddinXlamPath) {
        Write-Warning "AddinXlamPath 지정됐으나 파일 없음: $AddinXlamPath"
    }
}

function Invoke-SpoolProgressMacro {
    param(
        [Parameter(Mandatory=$true)] [string]$OpenPath,
        [Parameter(Mandatory=$true)] [string]$SaveAsPath,
        [Parameter(Mandatory=$true)] [string]$WoNo,
        [Parameter(Mandatory=$true)] [string]$SaveDir,
        [Parameter(Mandatory=$true)] [string]$MacroName,
        [string]$AddinName,
        [string]$AddinXlamPath,
        [switch]$ReloadAllAddins,
        [switch]$ShowExcelAlerts,
        [switch]$KeepExcelOpen,
        [switch]$DoSaveAs
    )

    $excel = $null
    $wb = $null
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $true
        $excel.DisplayAlerts = [bool]$ShowExcelAlerts
        $excel.AutomationSecurity = 1   # msoAutomationSecurityLow — xlam add-in 매크로 활성화

        Load-ExcelAddins -Excel $excel -MacroName $MacroName -AddinName $AddinName -AddinXlamPath $AddinXlamPath -ReloadAllAddins:$ReloadAllAddins
        Wait-ExcelReady -Excel $excel -TimeoutSec 60 | Out-Null

        $wb = $excel.Workbooks.Open($OpenPath)

        try {
            $sheet = $wb.Sheets.Item("Summary")
            $sheet.Range("C3").Value2 = $WoNo
            $sheet = $wb.Sheets.Item("실행")
            $sheet.Activate()
            $sheet.Range("K3").Value2 = $SaveDir
            Write-Host "==> '실행' 시트 활성화 + Summary Sheet C3='$WoNo', 실행 Sheet K3='$SaveDir'"
        } catch {
            Write-Warning "'실행' 시트 처리 실패: $($_.Exception.Message)"
        }

        if ($DoSaveAs) {
            $xlOpenXMLWorkbook = 51   # .xlsx (매크로 비저장)
            Write-Host "==> SaveAs (pre-macro): $SaveAsPath"
            $wb.SaveAs($SaveAsPath, $xlOpenXMLWorkbook)
        }

        Write-Host "==> 매크로 실행: $MacroName"
        $excel.Run($MacroName)
        Write-Host "==> 매크로 OK"

        try {
            $null = $wb.Name
            Write-Host "==> Save (post-macro)"
            $wb.Save()
            if (-not $KeepExcelOpen) {
                Write-Host "==> Close + Quit"
                $wb.Close($false)
                $excel.Quit()
            } else {
                Write-Host "==> Excel 열어둠 (-KeepExcelOpen)"
            }
        } catch {
            Write-Host "==> Workbook 이미 닫힘 (매크로가 자체 Save+Close 처리). 결과 파일: $SaveAsPath"
        }
    } finally {
        Release-ComObjectQuietly $wb
        if ($excel -and -not $KeepExcelOpen) {
            try { $excel.Quit() } catch { }
        }
        Release-ComObjectQuietly $excel
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}

function Get-XlsxFirstSheetRowCount {
    param([Parameter(Mandatory=$true)] [string]$Path)

    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $zip = $null
    $stream = $null
    $reader = $null
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $entry = $zip.GetEntry("xl/worksheets/sheet1.xml")
        if (-not $entry) { return $null }

        $stream = $entry.Open()
        $reader = [System.Xml.XmlReader]::Create($stream)
        $rows = 0
        while ($reader.Read()) {
            if ($reader.NodeType -eq [System.Xml.XmlNodeType]::Element -and $reader.LocalName -eq "row") {
                $rows++
            }
        }
        return $rows
    } catch {
        Write-Warning "입력 파일 행 수 확인 실패: $Path — $($_.Exception.Message)"
        return $null
    } finally {
        if ($reader) { $reader.Dispose() }
        if ($stream) { $stream.Dispose() }
        if ($zip) { $zip.Dispose() }
    }
}

function Test-SpoolProgressInputFiles {
    param(
        [Parameter(Mandatory=$true)] [string]$WoNo,
        [Parameter(Mandatory=$true)] [string]$SaveDir,
        [switch]$AllowEmptyOrderStatus
    )

    $suffixes = @(
        "MATL_TRACKING_LIST",
        "OPERDATE_OPER_ITEM",
        "ORDER_STATUS_LIST",
        "PPG_DRAWING_JOINT_LIST",
        "PPG_DRAWING_MBOM_LIST",
        "Spoolbom_Item_List",
        "SUBCONTRACT_ITEM_LIST"
    )

    Write-Host "==> ERP 입력 파일 행 수 확인"
    foreach ($suffix in $suffixes) {
        $path = Join-Path $SaveDir "$WoNo-$suffix.xlsx"
        if (-not (Test-Path $path)) {
            Write-Host "==> ERP 입력 파일 없음 $path"
            throw "ERP 입력 파일 없음: $suffix"
        }

        $rows = Get-XlsxFirstSheetRowCount -Path $path
        if ($null -eq $rows) {
            Write-Warning "    ${suffix}: 행 수 확인 불가"
        } else {
            Write-Host "    ${suffix}: $rows rows"
        }

        if ($suffix -eq "ORDER_STATUS_LIST" -and -not $AllowEmptyOrderStatus -and $null -ne $rows -and $rows -le 1) {
            throw "ORDER_STATUS_LIST에 데이터 행이 없습니다: $path. ERP 조회 결과가 비어 있어 Excel 매크로가 실패할 가능성이 높습니다. 데이터가 없는 WO가 맞다면 -AllowEmptyOrderStatus로 강제 진행할 수 있습니다."
        }
    }
}

function Remove-MacroFailureOutputFile {
    param(
        [Parameter(Mandatory=$true)] [string]$SaveAsPath,
        [Parameter(Mandatory=$true)] [string]$SaveDir
    )

    if (-not (Test-Path -LiteralPath $SaveAsPath)) {
        Write-Host "==> 삭제할 실패 산출물 없음: $SaveAsPath"
        return
    }

    $saveDirFull = [System.IO.Path]::GetFullPath($SaveDir).TrimEnd([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))
    $targetFull = [System.IO.Path]::GetFullPath($SaveAsPath)
    $allowedPrefix = $saveDirFull + [System.IO.Path]::DirectorySeparatorChar

    if (-not $targetFull.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Warning "실패 산출물 삭제 건너뜀: SaveDir 외부 경로입니다. target=$targetFull, SaveDir=$saveDirFull"
        return
    }

    for ($deleteAttempt = 1; $deleteAttempt -le 3; $deleteAttempt++) {
        try {
            Remove-Item -LiteralPath $targetFull -Force -ErrorAction Stop
            Write-Host "==> 매크로 실패 산출물 삭제: $targetFull"
            return
        } catch {
            Write-Warning "실패 산출물 삭제 실패 ($deleteAttempt/3): $($_.Exception.Message)"
            Start-Sleep -Seconds 1
        }
    }
}

# 0. 로그 디렉토리 결정 + Start-Transcript
if (-not $LogDir) {
    $logCandidates = @(
        'Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\logs',
        'Z:\공유받은 폴더\R&D(H0700)\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\logs'
    )
    foreach ($c in $logCandidates) {
        if (Test-Path $c) { $LogDir = $c; break }
    }
    if (-not $LogDir) {
        $LogDir = Join-Path $env:LOCALAPPDATA "ErpCtrl\logs"
        Write-Warning "공유서버 logs 폴더 접근 불가, fallback: $LogDir"
    }
}
$userLogDir = Join-Path $LogDir $env:USERNAME
if (-not (Test-Path $userLogDir)) {
    New-Item -ItemType Directory -Path $userLogDir -Force | Out-Null
}
$logTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $userLogDir "${logTimestamp}_run_spool_progress.log"
try { Start-Transcript -Path $logFile -Force | Out-Null } catch { Write-Warning "Start-Transcript 실패: $($_.Exception.Message)" }
Write-Host "==> log: $logFile"

# 1. 필수 인자 검증
if (-not $SaveDir)      { throw "SaveDir 누락: -SaveDir 또는 `$env:SAVE_DIR 설정" }
if (-not $UserId)       { throw "UserId 누락: -UserId 또는 `$env:USER_ID 설정" }
if (-not $Pwd)          { throw "Pwd 누락: -Pwd 또는 `$env:PWD 설정" }
if (-not $SherpExePath) { throw "SherpExePath 누락: -SherpExePath 또는 `$env:SHERP_EXE_PATH 설정" }

# erpctrl 위치 보정 (배포본 / dev 환경 모두 지원)
if (-not (Test-Path $ErpctrlExe)) {
    $devCmd = "dotnet"
    $devArgs = @("run", "--project", (Join-Path $ScriptDir "..\src\Erpctrl.Cli"), "--")
    Write-Host "==> erpctrl.exe not found at $ErpctrlExe, fallback to dev: dotnet run --project src/Erpctrl.Cli"
    $UseDev = $true
} else {
    $UseDev = $false
}

# 2. SHIIS 잔존 프로세스 정리
if (-not $NoCleanup) {
    Write-Host "==> SHIIS/Excel 잔존 프로세스 정리"
    Stop-Process -Name "shERP","shERP_main","erpctrl","coerp_mfg_operdate_oper","coerp_ppg_order_status","coerp_sub_spoolbom_pipecut","EXCEL" -Force -ErrorAction SilentlyContinue
}

if ($SkipErpctrl) {
    Write-Warning "SkipErpctrl 지정: ERP 데이터 다운로드 단계를 건너뛰고 기존 Excel 입력 파일로 진행."
} else {
    # 2.5. ErpCtrl 자동 업데이트 (배포본만, dev 환경은 skip)
    if (-not $UseDev -and -not $NoUpdate) {
        Write-Host "==> ErpCtrl 업데이트 체크"
        & $ErpctrlExe update
        $updExit = $LASTEXITCODE
        if ($updExit -ne 0) {
            Write-Warning "erpctrl update exit=$updExit (네트워크 단절 등). run 단계는 그대로 진행."
        }
    }

    # 3. erpctrl run 실행
    $varsArg = "USER_ID=$UserId,PWD=$Pwd,SHERP_EXE_PATH=$SherpExePath,WO_NO=$WoNo,SAVE_DIR=$SaveDir"
    Write-Host "==> erpctrl run --scenario $ScenarioPath"
    Write-Host "    vars: USER_ID=$UserId, WO_NO=$WoNo, SAVE_DIR=$SaveDir (PWD/SHERP_EXE_PATH masked)"

    if ($UseDev) {
        & $devCmd @devArgs run --scenario $ScenarioPath --vars $varsArg
    } else {
        & $ErpctrlExe run --scenario $ScenarioPath --vars $varsArg
    }
    $exitCode = $LASTEXITCODE
    Write-Host "==> erpctrl exit code: $exitCode"

    if ($exitCode -ne 0) {
        throw "erpctrl run 실패 (exit=$exitCode). Excel 단계 진행 중단."
    }
}

# Test-SpoolProgressInputFiles -WoNo $WoNo -SaveDir $SaveDir -AllowEmptyOrderStatus:$AllowEmptyOrderStatus

# # 4. Excel 보고서 파일 경로 결정
# $reportPath = Join-Path $SaveDir "$ReportPrefix$ReportSuffix"
# if (-not (Test-Path $reportPath)) {
#     throw "Excel 보고서 파일 없음: $reportPath"
# }
# Write-Host "==> Excel open: $reportPath"

# # 5. Excel COM — open + 매크로 실행 + save + close
# $today = Get-Date -Format "yyyyMMdd"
# $baseName = "$OutputPrefix-$WoNo-$today"
# $saveAsPath = Join-Path $SaveDir "$baseName.xlsx"
# $v = 1
# while (Test-Path $saveAsPath) {
#     $saveAsPath = Join-Path $SaveDir "${baseName}_V$v.xlsx"
#     $v++
# }

# try { Write-Host "==> PowerShell apartment: $($Host.Runspace.ApartmentState)" } catch { }

# $maxAttempts = 1 + [Math]::Max(0, $MacroRetryCount)
# $macroOk = $false
# $lastMacroError = $null

# for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
#     $isRetry = $attempt -gt 1
#     if ($isRetry) {
#         Write-Warning "매크로 재시도 $attempt/${maxAttempts}: $MacroRetryDelaySec 초 대기 후 새 Excel 인스턴스로 실행"
#         Start-Sleep -Seconds $MacroRetryDelaySec
#     }

#     $openPath = $reportPath
#     $doSaveAs = $true
#     if ($isRetry -and (Test-Path $saveAsPath)) {
#         $openPath = $saveAsPath
#         $doSaveAs = $false
#     }

#     try {
#         Invoke-SpoolProgressMacro `
#             -OpenPath $openPath `
#             -SaveAsPath $saveAsPath `
#             -WoNo $WoNo `
#             -SaveDir $SaveDir `
#             -MacroName $MacroName `
#             -AddinName $AddinName `
#             -AddinXlamPath $AddinXlamPath `
#             -ReloadAllAddins:$ReloadAllAddins `
#             -ShowExcelAlerts:$ShowExcelAlerts `
#             -KeepExcelOpen:$KeepExcelOpen `
#             -DoSaveAs:$doSaveAs
#         $macroOk = $true
#         break
#     } catch {
#         $lastMacroError = $_.Exception
#         Write-Warning "매크로 호출 실패 ($attempt/$maxAttempts): $($lastMacroError.Message)"
#         if (-not $KeepExcelOpen -and -not $NoCleanup) {
#             Write-Host "==> 실패한 Excel 인스턴스 정리"
#             Stop-Process -Name "EXCEL" -Force -ErrorAction SilentlyContinue
#         }
#         if ($attempt -eq $maxAttempts) {
#             Write-Warning "권장: -MacroName 에 fully-qualified name 사용 (예: `"'Smart Excel.xlam'!User_Design_Run`")"
#         }
#     }
# }

# if (-not $macroOk) {
#     Remove-MacroFailureOutputFile -SaveAsPath $saveAsPath -SaveDir $SaveDir
#     throw "Excel 매크로 실행 실패: $($lastMacroError.Message)"
# }

# Write-Host "==> 완료: $reportPath"

try { Stop-Transcript | Out-Null } catch { }
