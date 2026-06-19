---
name: erpctrl
description: "SHIIS3 ERP를 자연어 지시로 자동화하는 스킬. 사용자의 자연어 요청에 가장 유사한 시나리오를 찾아 erpctrl CLI로 실행한다. CLI는 공유서버에서 %APPDATA%\\erpctrl\\로 부트스트랩 후 사용. 사용 트리거: 'erpctrl', 'ERP 자동화', 'SHIIS3', 'SHIIS 자동화', 'ERP 매크로', 'ERP 원격제어', '자재코드 다운로드', '식수 입력', 'spool 진행', 'W/O 다운로드', '시나리오 실행'."
argument-hint: "<자연어로 하고 싶은 작업> -- 가장 유사한 시나리오를 찾아 실행"
---

# erpctrl — SHIIS3 ERP 자연어 자동화 실행기

사용자가 자연어로 지시하면, 공유서버에 배포된 `erpctrl.exe`를 `%APPDATA%\erpctrl\`에 준비한 뒤
가장 유사한 **시나리오(JSON)** 를 찾아 실행한다.

> CLI 바이너리는 이 플러그인에 포함되지 않는다. 실행 시점에 공유서버에서 가져온다.
> 시나리오 작성이 목적이면 `erpctrl-scenario` 스킬을 사용한다.

> ⚠️ **필수**: 어떤 작업이든 수행하기 전에 반드시 `erpctrl`의 `README.md`(`%APPDATA%\erpctrl\README.md`)를
> 먼저 읽고 숙지한다. (아래 Step 1.5)

## 핵심 경로

| 이름 | 경로 |
|---|---|
| 배포 위치(주 경로) | `Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl` |
| 로컬 설치(실행 위치) | `%APPDATA%\erpctrl` |
| 내장 시나리오 | `%APPDATA%\erpctrl\scenarios\*.json` |
| 사용자 시나리오 | `%APPDATA%\erpctrl\my_scenarios\*.json` |

공유서버 접근 불가 시(VPN/오프라인) **대체 경로 없이 즉시 중단**하고 원인을 안내한다.

---

## 절차

### Step 1 — 부트스트랩 & 동기화

아래 PowerShell을 실행한다. `%APPDATA%\erpctrl\erpctrl.exe`가 없으면 공유서버에서 최초 1회 복사(82MB, 수십 초)하고,
이미 있으면 `erpctrl update`로 시나리오/컨트롤을 서버 기준 최신화한다.

```powershell
$ErrorActionPreference = 'Stop'
$src = 'Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl'
$dst = Join-Path $env:APPDATA 'erpctrl'
$exe = Join-Path $dst 'erpctrl.exe'

if (-not (Test-Path $exe)) {
    if (-not (Test-Path $src)) {
        Write-Error "공유서버 접근 불가: $src`n네트워크 드라이브(Z:) 매핑 또는 VPN 연결을 확인한 뒤 다시 시도하세요."
        exit 1
    }
    Write-Host "==> 최초 부트스트랩: 공유서버 → $dst (약 82MB, 수십 초 소요)"
    $null = robocopy $src $dst /E /R:3 /W:5 /NFL /NDL /NJH /NJS /NC /NS
    if ($LASTEXITCODE -ge 8) { Write-Error "robocopy 실패 (exit $LASTEXITCODE)"; exit 1 }
}

# scenarios/controls 동기화 (매칭 전 최신화 보장). 서버 미접근 시 로컬 시나리오로 진행.
& $exe update
if ($LASTEXITCODE -ne 0) {
    Write-Warning "update 실패(exit $LASTEXITCODE). 로컬에 이미 받은 시나리오로 진행합니다."
}
& $exe --version
```

- robocopy 종료코드는 **8 미만이 성공**이다.
- `$src`에 공백·한글이 있으므로 항상 따옴표로 감싼다.

### Step 1.5 — README 숙지 (필수)

매칭/실행 전에 반드시 `erpctrl`의 `README.md`를 **Read 도구로 읽고 숙지**한다.
(부트스트랩/`update` 직후라 최신본이다.) README의 시나리오 표·변수 레퍼런스·액션 레퍼런스·
긴급정지·트러블슈팅·블록 카탈로그를 근거로 이후 단계를 수행한다.

- 1순위: `%APPDATA%\erpctrl\README.md`
- 폴백: `Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\README.md`
- 둘 다 없으면 사용자에게 보고하고 중단(부트스트랩 실패 가능성).

```powershell
$readme = Join-Path $env:APPDATA 'erpctrl\README.md'
if (-not (Test-Path $readme)) { $readme = 'Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\README.md' }
if (Test-Path $readme) { Write-Host "README 경로: $readme" } else { Write-Error "README.md 없음 — 부트스트랩 확인 필요" }
```

→ 출력된 경로를 Read로 읽어 내용을 숙지한 뒤 Step 2로 진행한다. SKILL.md의 요약표와 README가
다르면 **README를 우선**한다(서버 최신 반영).

### Step 2 — 시나리오 매칭

설치된 시나리오 목록을 `id`/`description`과 함께 추출한다 (`blocks/`는 include 전용이므로 제외).

```powershell
$dst = Join-Path $env:APPDATA 'erpctrl'
$dirs = @((Join-Path $dst 'scenarios'), (Join-Path $dst 'my_scenarios')) | Where-Object { Test-Path $_ }
Get-ChildItem -Path $dirs -Filter *.json -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch '\\blocks$' } |
    ForEach-Object {
        try {
            $j = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            [pscustomobject]@{ id = $j.id; file = $_.FullName; description = $j.description }
        } catch { }
    } | ConvertTo-Json -Depth 5
```

출력된 `description`(한글)을 사용자의 자연어 요청과 **의미 비교**하여 가장 유사한 시나리오 1건을 고른다.

- 매칭이 명확하면 선택 결과(시나리오 id + 한 줄 요약)를 사용자에게 알리고 진행.
- 두 개 이상이 비슷하거나 모호하면 후보를 제시하고 사용자에게 확인받는다.
- 적절한 시나리오가 없으면 `erpctrl-scenario` 스킬로 신규 작성을 제안한다.

매칭 참고용 대표 시나리오:

| 시나리오 | 자연어 매칭 예 |
|---|---|
| `smoke_notepad` | "엔진 동작 확인", "테스트" (SHIIS3 불요) |
| `pilot_sherp_login` | "로그인만 해줘" |
| `matlcode_search_by_category` | "자재코드 대분류별로 엑셀 받아줘" |
| `matlcode_puft_by_cost` | "자재코드 원가별 조회/다운로드" |
| `pilot_meal_v2` | "식수 입력", "일일 부서별 식수 현황" |
| `spool_progress_v2` | "W/O로 spool 진행/공정완료 엑셀 일괄 다운로드" |
| `spool_bom_progress` | "spool BOM 진행" |

### Step 3 — 변수 해석

매칭된 시나리오의 `description`과 아래 표에서 필수 `vars`를 도출한다.
**환경변수 우선**, 없으면 사용자에게 묻는다. `PWD`는 절대 파일에 저장하거나 콘솔/대화에 출력하지 않는다.

| 변수 | 의미 | 해석 순서 |
|---|---|---|
| `USER_ID` | SHIIS 사용자 ID | `$env:USER_ID` → 사용자 입력 |
| `PWD` | SHIIS 비밀번호 | `$env:PWD` → **실행 시점 입력**(저장 금지) |
| `SHERP_EXE_PATH` | launcher exe 경로 | `$env:SHERP_EXE_PATH` → 사용자 입력 |
| `SHERP_MAIN_EXE_PATH` | main exe 경로 | `$env:SHERP_MAIN_EXE_PATH` → 사용자 입력 |

> SHERP 경로는 영구 환경변수 등록을 권장:
> ```powershell
> [System.Environment]::SetEnvironmentVariable("SHERP_EXE_PATH","C:\SHIIS3\shERP.exe","User")
> [System.Environment]::SetEnvironmentVariable("SHERP_MAIN_EXE_PATH","C:\SHIIS3\shERP_main.exe","User")
> ```

### Step 4 — 실행

`--vars`로 변수를 주입해 시나리오를 실행한다. (PowerShell 자동변수 `$PWD`(현재 디렉터리)와 충돌하지 않도록 비밀번호는 `$ErpPwd` 등 다른 이름을 쓴다.)

> 🔑 **`--vars`는 콤마(`,`)로 구분된 "단일 인자"** 다 (`--vars "K1=V1,K2=V2"`).
> PowerShell 배열을 `--vars @vars`처럼 splat하면 **첫 변수만** 파싱되고 나머지는 무시되어
> `${WO_NO}` 같은 리터럴이 남는다. 반드시 `($pairs -join ',')`로 **하나의 문자열**로 합쳐 넘긴다.
>
> ⚠️ **값에 콤마가 포함된 변수**(예: `MEAL_DATES=2026-05-21,2026-05-22`)는 `--vars`로 넘길 수 없다
> (콤마가 구분자로 오인됨). 이런 변수는 `$env:`로 주입한다 — CLI가 환경변수도 자동 주입한다.

검증된 실행 패턴(`tools/run_spool_progress.ps1` line 393과 동일):

```powershell
$dst = Join-Path $env:APPDATA 'erpctrl'
$exe = Join-Path $dst 'erpctrl.exe'
$scenario = Join-Path $dst 'scenarios\matlcode_search_by_category.json'   # 매칭 결과로 치환

# 변수값 준비 (환경변수 우선, PWD 미설정 시 입력)
$ErpPwd  = $env:PWD                       # 없으면 실행 시점에 입력받아 대입
$WoNo    = "P250129-01"                   # 시나리오에 WO_NO 필요 시
$SaveDir = "D:\tmp"                       # 시나리오에 SAVE_DIR 필요 시

# ★ --vars 는 "하나의 콤마-구분 문자열". 시나리오가 요구하는 키만 포함한다.
$varsArg = "USER_ID=$env:USER_ID,PWD=$ErpPwd,SHERP_EXE_PATH=$env:SHERP_EXE_PATH,WO_NO=$WoNo,SAVE_DIR=$SaveDir"

& $exe run --scenario $scenario --vars $varsArg
"exit code: $LASTEXITCODE"
```

- **절대 `--vars @arr`(배열 splat)나 `--vars A B`(공백 토큰)로 넘기지 말 것** — 첫 변수만 파싱되어 `${WO_NO}` 리터럴이 남는다.
- 값에 콤마가 있는 변수(예: `MEAL_DATES=2026-05-21,2026-05-22`)는 `--vars`에 넣지 말고 `$env:MEAL_DATES = "..."`로 주입(CLI가 환경변수도 자동 주입).

- 사용자 시나리오 실행 시 블록 include가 깨지지 않도록 환경변수 설정:
  ```powershell
  $env:ERPCTRL_BLOCKS_DIR = Join-Path $env:APPDATA 'erpctrl\scenarios\blocks'
  ```
- 실행 결과는 `logs\<UserName>\<run-id>\result.json`에 기록된다. 경로를 사용자에게 안내한다.

### Step 5 — 결과 보고

종료 코드로 성패를 판정해 사용자에게 보고한다.

| 코드 | 의미 | 조치 |
|---|---|---|
| 0 | 성공 | result.json·스크린샷 경로 안내 |
| 2 | 시나리오 실패 | run.log의 실패 step 확인 |
| 3 | 컨트롤 식별 실패 | run.log 윈도우 dump에서 실제 컨트롤명 확인 → 시나리오 수정(`erpctrl-scenario`) |
| 4 | 프로세스 기동 실패 | SHERP 경로/잔존 프로세스 확인 |
| 5 | 사용자 중단(ESC) | abort.png 확인, 필요 시 재실행 |

---

## 긴급 정지

실행 중 **ESC** 키로 다음 step 경계에서 안전 중단(SHIIS UI에 focus가 있어도 동작).
진행 중인 step(예: `sleep`)은 끝까지 진행 후 종료.

## 주의사항

- 잔존 프로세스가 실행을 방해하면 정리: `Stop-Process -Name "shERP","shERP_main","erpctrl","coerp_gen_sigsu" -Force -ErrorAction SilentlyContinue`
- 첫 실행 시 SmartScreen 경고: "추가 정보 → 실행".
- 비밀번호는 어떤 경우에도 평문 출력/저장하지 않는다(`--vars`로 주입 시 CLI가 자동 마스킹).
- `scenarios\`는 `update` 시 서버 기준으로 미러(삭제 포함)된다. 직접 만든 시나리오는 `my_scenarios\`에 둔다.

## 추가 도움

- `& "$env:APPDATA\erpctrl\erpctrl.exe" --help`
- `& "$env:APPDATA\erpctrl\erpctrl.exe" run --help`
- 새 시나리오 작성: `erpctrl-scenario` 스킬
