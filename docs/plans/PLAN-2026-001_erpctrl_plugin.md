# PLAN-2026-001: ERPCTRL CLI Claude Code 플러그인화

- **상태**: Pending (사용자 검토 대기)
- **작성일**: 2026-06-19
- **작성자**: dh-dev orchestrator (이동훈, R&D 연구개발부)
- **대상 저장소**: `D:\001_Work\2026\040_ERP_Ctrl\erpctrl_plugin` → `git@github.com:Donghun1q2w/ERPctrl.git`
- **참조 CLI 저장소**: `D:\001_Work\2026\040_ERP_Ctrl\ERP_Remote_Control` (플러그인에 **미포함**)

## 1. 목표

SHIIS3 ERP UI 자동화 CLI(`erpctrl.exe`)를 Claude Code **플러그인**으로 래핑하여,
자연어 지시만으로 가장 유사한 시나리오를 찾아 실행하고, 새 시나리오를 생성할 수 있게 한다.

핵심 제약:
- 플러그인은 CLI 바이너리·소스 저장소를 **번들하지 않는다** (82MB exe 미포함).
- 스킬 실행 시 **배포 위치(공유서버)** 에서 `%APPDATA%\erpctrl\` 로 CLI를 부트스트랩하고, 이후 exe의 자동 동기화에 위임한다.

## 2. 배경 / 확인된 사실

- **CLI**: `erpctrl.exe` (.NET 8 self-contained, 약 82MB). 명령: `run --scenario <경로> --vars K=V`, `analyze`, `discover`, `update`, `--version`, `--help`, `--no-update-check`, `--logs`.
- **배포 위치(주 경로)**: `Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\` (접근 확인됨).
  - 구성: `erpctrl.exe`, `VERSION`(현재 `2026.06.11-a6e8b5f`), `scenarios/`(+`blocks/`), `controls/`, `README.md`, `CHANGELOG.md`.
- **시나리오**: 각 JSON에 한글 `description`(풍부) + `id` + `steps` + 필수 `vars` 보유. 자연어 매칭의 1차 근거로 사용.
- **`update` 동작**: `scenarios/`(+`blocks/`)·`controls/`를 서버 기준으로 **미러(서버에 없는 로컬 파일 삭제)**. 사용자 작성 시나리오는 `scenarios/` 밖(별도 폴더)에 둬야 보존됨. `ERPCTRL_BLOCKS_DIR` 로 블록 경로 해석 가능.
- **긴급 정지**: 실행 중 ESC. 종료 코드: 0 성공 / 2 시나리오 실패 / 3 컨트롤 식별 실패 / 4 프로세스 기동 실패 / 5 사용자 중단.
- **로그**: `logs\<UserName>\<run-id>\result.json` + 스크린샷.

### 확정된 설계 결정 (사용자 답변)

| 항목 | 결정 |
|---|---|
| `%APPDATA%\erpctrl\` 배치 | exe 실행 시 자동 업데이트. 최초 1회 부트스트랩 복사 후 exe(`update`)가 동기화 담당 |
| 공유서버 접근 불가 시 | **주 경로만** 시도, 실패 시 명확히 보고 후 **중단** (대체 경로 없음) |
| 시나리오 생성 저장 위치 | `%APPDATA%\erpctrl\my_scenarios\` **에만** (update 미러에 안 지워짐) |
| 민감 변수(PWD 등) | 환경변수 우선, 없으면 실행 시점에 입력받음. 파일 저장 안 함 |

## 3. 플러그인 구조 (산출물)

```
erpctrl_plugin/
├── .claude-plugin/
│   ├── plugin.json          # 플러그인 매니페스트 (name, version, description)
│   └── marketplace.json     # 자기 자신을 가리키는 마켓플레이스 항목 (source "./")
├── skills/
│   ├── erpctrl/
│   │   └── SKILL.md         # [스킬1] 자연어 → 시나리오 매칭 → 실행
│   └── erpctrl-scenario/
│       └── SKILL.md         # [스킬2] 시나리오 생성
├── README.md                # 설치/사용법 (한글)
├── docs/
│   ├── plans/PLAN-2026-001_erpctrl_plugin.md
│   └── plan_history.md
└── .gitignore
```

## 4. 스킬 설계

### 스킬1 — `erpctrl` (실행기)

**Frontmatter**: `name: erpctrl`, 한/영 트리거 포함 description
(예: "SHIIS3 ERP 자동화", "erpctrl 실행", "ERP 매크로", "자재코드 다운로드", "식수 입력", "spool 진행", "ERP remote control").

**워크플로우 (SKILL.md 본문에 명시할 절차)**:

1. **부트스트랩 & 동기화** (PowerShell, UTF-8):
   - `$src = 'Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl'`
   - `$dst = "$env:APPDATA\erpctrl"`
   - `$dst\erpctrl.exe` 없으면 → `robocopy $src $dst /E` 로 부트스트랩. `$src` 접근 불가 시 **즉시 중단**하고 원인(네트워크 드라이브/VPN) 안내.
   - exe 존재 후 `& "$dst\erpctrl.exe" update` 실행으로 `scenarios/`·`controls/` 서버 동기화(매칭 전 시나리오 최신화 보장). update 실패 + 로컬 시나리오 존재 시 best-effort 진행, 그 외 중단.
2. **시나리오 매칭**:
   - `$dst\scenarios\*.json` + `$dst\my_scenarios\*.json` 의 `id`/`description` 수집.
   - 사용자 자연어 요청과 description 의미 비교 → 최상위 매칭 1건 + 대안 제시. 모호하면 사용자에게 확인.
3. **변수 해석**:
   - 매칭 시나리오의 `description`·README 변수표에서 필수 `vars` 도출.
   - 환경변수 우선(`$env:USER_ID`, `$env:SHERP_EXE_PATH` 등). `PWD`는 `$env:PWD` 있으면 사용, 없으면 **실행 시점에 입력**받음(파일 저장 금지, 로그 노출 금지).
   - 누락된 비민감 변수도 사용자에게 질문.
4. **실행**:
   - `& "$dst\erpctrl.exe" run --scenario "<경로>" --vars KEY=VAL ...`
   - 콘솔 출력·exit code 해석, `result.json` 경로 안내. PWD는 출력/로그에 남기지 않음.
5. **안내**: ESC 긴급정지, 종료 코드 표, 로그 위치.

### 스킬2 — `erpctrl-scenario` (시나리오 생성기)

**Frontmatter**: `name: erpctrl-scenario`, 트리거(예: "ERP 시나리오 생성", "erpctrl 시나리오 작성", "새 매크로 만들기", "SHIIS3 자동화 시나리오").

**워크플로우**:

1. CLI 존재 보장(스킬1과 동일 부트스트랩 로직).
2. 대상 워크플로우 파악(모듈/메뉴/단계 인터뷰).
3. 컨트롤 이름 확보:
   - 정적: `erpctrl analyze --exe <모듈.exe> --out controls\`
   - 동적: `erpctrl discover --window-title "<윈도우>" --out controls\live_xxx.json` (SHIIS 실행 중).
4. **블록 우선 재사용**: `login_sherp` / `module_open` / `lookup_popup` / `file_dialog_save` / `file_dialog_upload` / `modal_2step` 확인 후 `include`.
5. JSON 시나리오 작성 → `%APPDATA%\erpctrl\my_scenarios\<id>.json` **에만** 저장.
   - `include` 블록 경로는 `ERPCTRL_BLOCKS_DIR=%APPDATA%\erpctrl\scenarios\blocks` 환경변수로 해석.
6. 검증: 가능하면 smoke/부분 실행으로 동작 확인 후 결과 보고.
7. 액션 레퍼런스(launch/waitWindow/click/setText/setDate/forEach/include 등)를 본문에 요약 수록.

## 5. 구현 단계 (Implementation Steps)

1. **저장소 초기화**: `erpctrl_plugin`에 `git init`, 원격 `git@github.com:Donghun1q2w/ERPctrl.git` 추가, `.gitignore` 작성.
2. **`.claude-plugin/plugin.json`** 작성 (name `erpctrl`, version `0.1.0`, description, author).
3. **`.claude-plugin/marketplace.json`** 작성 (dh-skills 규약 미러, source `./`).
4. **`skills/erpctrl/SKILL.md`** 작성 — §4 스킬1 워크플로우, PowerShell 스니펫(UTF-8), 종료코드/ESC/변수표.
5. **`skills/erpctrl-scenario/SKILL.md`** 작성 — §4 스킬2 워크플로우, analyze/discover/블록/액션 레퍼런스.
6. **`README.md`** 작성 — 설치(마켓플레이스 add / plugin install), 두 스킬 사용 예시, 사전조건(공유서버 접근, SHERP 환경변수).
7. **`docs/plan_history.md`** 인덱스 작성.
8. **검증**: PowerShell로 부트스트랩 스니펫 dry-run(공유서버 접근·robocopy 경로 확인, exe 미복사 모드), JSON 매니페스트 유효성 검사, 스킬 frontmatter 형식 점검.

## 6. Acceptance Criteria (before/after)

- **Before**: erpctrl는 PowerShell에서 수동으로 경로/변수를 조합해 실행해야 함. 시나리오 선택·변수 입력이 수작업.
- **After**:
  - [ ] 플러그인이 CLI 바이너리를 포함하지 않는다 (저장소에 `*.exe` 없음 — `.gitignore`로 차단).
  - [ ] `erpctrl` 스킬 실행 시 `%APPDATA%\erpctrl\`에 CLI가 부트스트랩되고 `update`로 동기화된다 (공유서버 미접근 시 명확히 중단).
  - [ ] 자연어 지시(예: "자재코드 대분류별로 엑셀 받아줘")가 `matlcode_search_by_category` 시나리오로 매칭되어 실행된다.
  - [ ] 필수 변수는 환경변수 우선, PWD 미설정 시 실행 시점 입력. 평문 저장·로그 노출 없음.
  - [ ] `erpctrl-scenario` 스킬이 새 시나리오를 `%APPDATA%\erpctrl\my_scenarios\`에만 생성한다.
  - [ ] `plugin.json`/`marketplace.json`이 유효하고 두 스킬이 frontmatter 규약을 만족한다.
  - [ ] README로 설치·사용이 재현 가능하다.

## 7. 리스크 / 메모

- `run`의 자동 동기화 범위가 README상 "알림만"일 수 있어, 매칭 전 시나리오 최신화를 위해 **명시적 `update` 호출**로 보완(검증 단계에서 실제 동작 확인).
- 공유서버 경로에 공백/한글 포함 → PowerShell 인용 주의.
- 82MB exe robocopy 최초 1회는 수십 초 소요 가능 → 사용자 안내.
- PWD `--vars` 주입 시 README상 자동 마스킹되나, 스킬은 추가로 콘솔/대화에 PWD를 출력하지 않도록 명시.
