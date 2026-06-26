---
name: erpctrl-scenario
description: "SHIIS3 ERP 자동화용 erpctrl 시나리오(JSON)를 새로 작성하는 스킬. 대상 모듈의 컨트롤을 analyze/discover로 확보하고, 기존 블록을 재사용해 시나리오를 만들어 %APPDATA%\\erpctrl\\my_scenarios\\에 저장한다. 사용 트리거: 'erpctrl 시나리오 생성', 'ERP 시나리오 작성', '새 매크로 만들기', 'SHIIS3 자동화 시나리오', '시나리오 만들어줘', 'ERP 자동화 스크립트 작성'."
argument-hint: "<자동화하려는 SHIIS3 작업 설명> -- 새 시나리오 JSON 생성"
---

# erpctrl-scenario — 시나리오 생성기

새 SHIIS3 워크플로우를 erpctrl 시나리오(JSON)로 작성한다. 결과는 **`%APPDATA%\erpctrl\my_scenarios\`에만** 저장한다.
(`scenarios\`는 `erpctrl update` 시 서버 기준 미러로 삭제되므로 직접 작성 시나리오를 두면 유실된다.)

> 기존 시나리오를 실행만 하려면 `erpctrl` 스킬을 사용한다.

> ⚠️ **필수**: 시나리오를 작성하기 전에 반드시 `erpctrl`의 `README.md`(`%APPDATA%\erpctrl\README.md`)를
> 먼저 읽고 숙지한다 — 특히 액션 레퍼런스·블록 카탈로그·시나리오 작성 가이드·트러블슈팅. (아래 Step 1.5)

## 절차

### Step 1 — CLI 준비

`erpctrl` 스킬 Step 1과 동일하게 부트스트랩한다.

```powershell
$ErrorActionPreference = 'Stop'
$src = 'Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl'
$dst = Join-Path $env:APPDATA 'erpctrl'
$exe = Join-Path $dst 'erpctrl.exe'
if (-not (Test-Path $exe)) {
    if (-not (Test-Path $src)) { Write-Error "공유서버 접근 불가: $src (Z: 매핑/VPN 확인)"; exit 1 }
    $null = robocopy $src $dst /E /R:3 /W:5 /NFL /NDL /NJH /NJS /NC /NS
    if ($LASTEXITCODE -ge 8) { Write-Error "robocopy 실패 (exit $LASTEXITCODE)"; exit 1 }
}
& $exe update 2>$null
New-Item -ItemType Directory -Force (Join-Path $dst 'my_scenarios') | Out-Null
```

### Step 1.5 — README 숙지 (필수)

시나리오 작성 전에 반드시 `erpctrl`의 `README.md`를 **Read 도구로 읽고 숙지**한다.
액션 레퍼런스·블록 카탈로그·시나리오 작성 가이드·트러블슈팅을 근거로 작성한다.

- 1순위: `%APPDATA%\erpctrl\README.md`
- 폴백: `Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\README.md`
- 둘 다 없으면 사용자에게 보고하고 중단.

```powershell
$readme = Join-Path $env:APPDATA 'erpctrl\README.md'
if (-not (Test-Path $readme)) { $readme = 'Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\README.md' }
if (Test-Path $readme) { Write-Host "README 경로: $readme" } else { Write-Error "README.md 없음 — 부트스트랩 확인 필요" }
```

→ 출력된 경로를 Read로 읽어 숙지한 뒤 Step 2로 진행한다. SKILL.md 요약과 README가 다르면 **README를 우선**한다.

### Step 2 — 워크플로우 인터뷰

사용자에게 다음을 확인한다:
- 대상 SHIIS3 모듈/메뉴 경로 (예: `구매 > 기초자료 등록 > 자재코드 조회`)
- 수행 단계(로그인 → 메뉴 진입 → 검색 → 다운로드/입력 → 저장 등)
- 반복 여부(여러 일자, 콤보 항목 전체 등)
- 필요한 변수(USER_ID/PWD/경로/WO_NO 등)

### Step 2.5 — ERP 메뉴 트리 탐색 및 검증 (필수)

메뉴에서 기능을 열고 윈도우 scope를 전환하는 시나리오를 작성할 때는 반드시
`ref\erp_menu_tree.json`을 먼저 읽어 메뉴 경로와 모듈을 탐색/검증한다.

- 개발 저장소 기준 경로: `D:\001_Work\2026\040_ERP_Ctrl\erpctrl_plugin\skills\erpctrl-scenario\ref\erp_menu_tree.json`
- 설치본/플러그인 패키지 기준 경로: 이 `SKILL.md`가 있는 스킬 폴더의 `ref\erp_menu_tree.json`
- `path`는 `openMenu`/`blocks/module_open.json`의 `MENU_PATH`에 넣을 정확한 문자열이다. 사용자가 말한 메뉴명을 임의로 보정하지 말고, leaf 항목의 `path`를 그대로 사용한다.
- `name`은 실제 메뉴 UIA 텍스트이며, `module`은 `C:\SHIIS3\<module>.exe` 분석 대상 EXE명이다. Step 3의 `analyze --exe` 대상은 선택한 leaf 메뉴의 `module`과 일치해야 한다.
- `active:false` 메뉴는 비활성/미사용 가능성이 있으므로 사용자 확인 없이 시나리오 대상으로 확정하지 않는다.
- `WINDOW_TITLE`은 메뉴 트리만으로 단정하지 않는다. `MENU_PATH`로 기능을 연 뒤 실제 윈도우 제목을 `waitWindow`/`discover`/윈도우 목록/실행 로그로 확인해 `WINDOW_TITLE`에 반영한다.
- 후보가 둘 이상이거나 `path`/`module`을 확정할 수 없으면, 후보 `path`, `module`, `active` 값을 제시하고 사용자 확인을 받는다.

메뉴 트리 검색 예:

```powershell
$menuTree = Get-Content 'D:\001_Work\2026\040_ERP_Ctrl\erpctrl_plugin\skills\erpctrl-scenario\ref\erp_menu_tree.json' -Raw -Encoding UTF8 | ConvertFrom-Json
function Find-ErpMenu($nodes, [string]$pattern) {
    foreach ($n in $nodes) {
        if (($n.path -like "*$pattern*") -or ($n.name -like "*$pattern*") -or ($n.module -like "*$pattern*")) {
            [pscustomobject]@{ path = $n.path; name = $n.name; module = $n.module; active = $n.active }
        }
        if ($n.children) { Find-ErpMenu $n.children $pattern }
    }
}
Find-ErpMenu $menuTree.tree '자재코드'
```

### Step 3 — 컨트롤 이름 확보

**정적 분석** (대상 모듈 exe의 폼/컨트롤/이벤트 메타데이터):

```powershell
& "$env:APPDATA\erpctrl\erpctrl.exe" analyze --exe C:\SHIIS3\<대상모듈>.exe --out "$env:APPDATA\erpctrl\controls\"
```

`<대상모듈>`은 Step 2.5에서 선택한 `erp_menu_tree.json` leaf 메뉴의 `module` 값과 일치해야 한다.
예: `module`이 `coerp_mat_item`이면 `C:\SHIIS3\coerp_mat_item.exe`를 분석한다.

**런타임 discover** (메뉴 등 동적 컨트롤 — SHIIS 실행 중일 때 별도 터미널):

```powershell
& "$env:APPDATA\erpctrl\erpctrl.exe" discover --window-title "<원하는 윈도우>" --out "$env:APPDATA\erpctrl\controls\live_xxx.json"
```

생성된 `controls\<module>.json`에서 실제 `name`/`id`를 확인한다.
- WinForms `ToolStripButton`(메인 toolbar)은 `Name`만 visible text(`Search`/`Update`/`Insert` 등)로 노출.
- FarPoint FpSpread 셀은 UIA 미노출 → 좌표 기반 `gridDoubleClickRowAt` 사용.
- `SysDateTimePick32`는 `setDate` 액션 사용.

### Step 4 — 블록 우선 재사용

반복 시퀀스는 `scenarios/blocks/*.json`을 `include`로 호출한다. **새로 짜기 전 항상 확인.**
메뉴 진입이 필요한 경우 `blocks/module_open.json`을 우선 사용하되, `MENU_PATH`는 반드시 Step 2.5에서
검증한 `erp_menu_tree.json`의 leaf `path`를 사용하고, `WINDOW_TITLE`은 실제 기능 오픈 후 확인한 제목을 넣는다.

| 블록 | 용도 | 주요 vars |
|---|---|---|
| `blocks/login_sherp.json` | launcher → coEIS → Sign In → SHIIS main 진입 | `SHERP_EXE_PATH`, `USER_ID`, `PWD` |
| `blocks/module_open.json` | 메뉴 진입 + 윈도우 scope 전환 (`MENU_PATH`는 `erp_menu_tree.json` leaf `path`와 정확히 일치) | `MENU_PATH`, `WINDOW_TITLE`, `WAIT_AFTER_OPEN_MS` |
| `blocks/lookup_popup.json` | Site/Dept/W/O lookup popup 검색 + 첫 row 더블클릭 + 복귀 | `BTN_LOOKUP`, `POPUP_TITLE`, `SEARCH_FIELD`, `SEARCH_VALUE`, `SEARCH_BTN`, `RETURN_WINDOW` |
| `blocks/file_dialog_save.json` | SaveFileDialog typeKeys + 저장(S) | `TRIGGER_BTN`, `FILE_PATH`, `SAVE_BTN` |
| `blocks/file_dialog_upload.json` | OpenFileDialog typeKeys + ENTER | `TRIGGER_BTN`, `FILE_PATH` |
| `blocks/modal_2step.json` | DB 조작 2단 popup(confirm+result) ENTER | `TRIGGER_BTN`, `CONFIRM_SLEEP_MS`, `RESULT_SLEEP_MS` |

include 호출 예:
```jsonc
{ "step": 1, "action": "include", "value": "blocks/login_sherp.json",
  "vars": { "SHERP_EXE_PATH": "${SHERP_EXE_PATH}", "USER_ID": "${USER_ID}", "PWD": "${PWD}" } }
```

### Step 5 — 시나리오 JSON 작성

`scenarios\matlcode_search_by_category.json` 또는 `scenarios\spool_progress_v2.json`을 템플릿으로 삼아 작성하고
`%APPDATA%\erpctrl\my_scenarios\<id>.json`에 저장한다.

기본 형식:
```jsonc
{
  "id": "<kebab-or-snake-id>",
  "description": "무엇을 하는지 + 흐름 + 필수 vars 를 한글로 풍부하게. (erpctrl 스킬의 자연어 매칭 근거가 됨)",
  "defaultTimeoutMs": 15000,
  "steps": [
    { "step": 1, "action": "include", "value": "blocks/login_sherp.json",
      "vars": { "SHERP_EXE_PATH": "${SHERP_EXE_PATH}", "USER_ID": "${USER_ID}", "PWD": "${PWD}" } },
    { "step": 2, "action": "include", "value": "blocks/module_open.json",
      "vars": {
        "MENU_PATH": "<erp_menu_tree.json의 leaf path 그대로>",
        "WINDOW_TITLE": "<기능 오픈 후 확인한 실제 윈도우 제목>",
        "WAIT_AFTER_OPEN_MS": "2500"
      } }
    // ... 실제 작업 step
  ]
}
```

> **`description`은 풍부하게 작성한다.** `erpctrl` 스킬이 이 문장으로 자연어 요청을 매칭하므로,
> 용도·흐름·필수 변수를 명확히 적을수록 매칭 정확도가 올라간다.

블록 경로 해석을 위해 실행 시 환경변수 설정:
```powershell
$env:ERPCTRL_BLOCKS_DIR = Join-Path $env:APPDATA 'erpctrl\scenarios\blocks'
```

### Step 6 — 검증

작성 직후 실제 실행해 동작을 확인한다(자기검증 원칙).

```powershell
$dst = Join-Path $env:APPDATA 'erpctrl'
$env:ERPCTRL_BLOCKS_DIR = Join-Path $dst 'scenarios\blocks'

# ★ --vars 는 "하나의 콤마-구분 문자열" (절대 배열 splat/공백 토큰 금지 → 첫 변수만 파싱됨).
#    값에 콤마가 있는 변수(MEAL_DATES 등)는 $env: 로 주입한다 (CLI가 환경변수도 자동 주입).
$ErpPwd  = $env:PWD
$varsArg = "USER_ID=$env:USER_ID,PWD=$ErpPwd,SHERP_EXE_PATH=$env:SHERP_EXE_PATH"   # 시나리오에 맞춰 WO_NO/SAVE_DIR 등 추가
& "$dst\erpctrl.exe" run --scenario "$dst\my_scenarios\<id>.json" --vars $varsArg
"exit code: $LASTEXITCODE"
```

- exit 0이면 `result.json`·스크린샷 경로를 보고.
- 메뉴 오픈/윈도우 전환이 실패하면 `erp_menu_tree.json`의 `path`, `module`, `active`를 다시 확인하고,
  실제 오픈된 윈도우 제목을 `discover`/로그/윈도우 목록으로 재검증한 뒤 `MENU_PATH` 또는 `WINDOW_TITLE`을 수정한다.
- exit 3(컨트롤 식별 실패)이면 run.log의 윈도우 dump에서 실제 컨트롤명을 확인해 step을 수정하고 재실행.
- SHIIS3가 없는 환경이면 `smoke_notepad`/`smoke_include`로 엔진 동작만 확인.

## 액션 레퍼런스

| action | 용도 |
|---|---|
| `launch` | exe 실행 |
| `waitWindow` | 같은 프로세스 윈도우 타이틀 대기 |
| `switchWindow` | 윈도우 scope 변경 |
| `attachApp` | cross-process 윈도우 진입(`Application.Attach`) |
| `waitEnabled` | 컨트롤 `IsEnabled=true` 대기 |
| `openMenu` | 메뉴 경로 다단 클릭(`A > B > C`) |
| `click` | 클릭(`physicalClick:true`면 InvokePattern 우회) |
| `setText` | 텍스트 입력(`useTyping:true`면 키 타이핑 강제) |
| `setDate` | DateTimePicker 전용 |
| `selectCombo` | ComboBox 선택 |
| `check` | CheckBox 토글 |
| `pressKey` / `typeKeys` | 키 입력 / focus에 문자열 타이핑 |
| `gridDoubleClickRow` / `gridDoubleClickRowAt` | 그리드 row 더블클릭(텍스트/좌표) |
| `doubleClick` | 단일 컨트롤 더블클릭 |
| `forEach` / `forEachComboItem` | 변수 루프 / 콤보 항목 전체 순회 |
| `clickFirstEnabled` | 두 후보 중 enabled 클릭 |
| `screenshot` / `sleep` | 캡처 / 대기(ms) |
| `readText` / `assertText` | 텍스트 읽기·검증(`storeAs`로 재사용) |
| `include` | 블록 호출(inner steps inline 전개, `vars` 주입) |
| `mkdir` / `deleteFile` / `backupFile` | 폴더 생성 / 파일 삭제 / 백업 |

## 자주 겪는 문제

| 증상 | 원인/해결 |
|---|---|
| `Control not found` | 컨트롤명 불일치. run.log 윈도우 dump에서 실제 name/id 확인 |
| `COMException 0x80040201` (click) | modal 여는 버튼은 InvokePattern block → `"physicalClick": true` |
| `gridDoubleClickRow: 0 candidates` | FpSpread는 셀 미노출 → `gridDoubleClickRowAt`(좌표) |
| DateTimePicker 값 안 받음 | `setDate` 사용 |
| Update 후 다음 iteration disabled | 저장 confirmation popup → `pressKey ENTER`로 dismiss |
