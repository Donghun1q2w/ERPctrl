# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this dual Claude Code / Codex plugin repository.

## 이 저장소의 정체성

이 저장소는 **코드가 아니라 Claude Code / Codex 플러그인 패키지**다. 빌드/컴파일/테스트 파이프라인이 없다.
산출물은 Markdown 스킬 정의(`skills/**/SKILL.md`)와 JSON 매니페스트(`.claude-plugin/*.json`, `.codex-plugin/plugin.json`)뿐이다.

실제 자동화를 수행하는 `erpctrl.exe`(SHIIS3 ERP UI 자동화, .NET 8)는 **이 저장소에 포함되지 않는다**
(`.gitignore`가 `*.exe`/`*.dll`/`*.pdb`를 제외). CLI 본체는 별도 저장소 `ERP_Remote_Control`에 있고,
스킬 실행 시점에 공유서버에서 `%APPDATA%\erpctrl\`로 부트스트랩된다. 따라서 이 저장소에서 편집하는 것은
**"CLI를 자연어로 구동하는 절차서(스킬)"** 이지 CLI 자체가 아니다.

## 아키텍처 — 스킬 2개의 역할 분리

| 스킬 | 파일 | 역할 |
|---|---|---|
| `erpctrl` | `skills/erpctrl/SKILL.md` | 자연어 요청 → 가장 유사한 시나리오 JSON 매칭 → CLI 실행 |
| `erpctrl-scenario` | `skills/erpctrl-scenario/SKILL.md` | 새 시나리오 JSON 작성 → `%APPDATA%\erpctrl\my_scenarios\`에 저장 |

두 스킬이 공유하는 런타임 모델(여러 파일을 읽어야 보이는 큰 그림):

1. **부트스트랩**: `%APPDATA%\erpctrl\erpctrl.exe`가 없으면 공유서버(`Z:\그룹 공유\...\ErpCtrl`)에서 robocopy로 최초 1회 복사(약 82MB). robocopy는 **exit < 8 이 성공**.
2. **동기화**: 이미 있으면 `erpctrl update`로 `scenarios/`·`controls/`를 서버 기준 미러링. `scenarios/`는 update 시 **삭제 포함 미러**되므로 사용자 작성물은 반드시 `my_scenarios/`에 둔다.
3. **README-first(필수)**: 매칭/작성 전에 항상 `%APPDATA%\erpctrl\README.md`를 Read로 읽는다. SKILL.md 요약표와 README가 다르면 **README가 우선**(서버 최신 반영). 이 단계를 생략하지 말 것.
4. **매칭**: 각 시나리오 JSON의 한글 `description`을 자연어 요청과 의미 비교해 1건 선택. `blocks/`는 include 전용이라 매칭 후보에서 제외.
5. **변수**: 환경변수 우선, `PWD`는 미설정 시 실행 시점 입력(저장·콘솔 출력 금지).
6. **실행**: `erpctrl run --scenario <경로> --vars "K1=V1,K2=V2"`.

시나리오 JSON은 `action` step의 배열이며, 반복 시퀀스는 `scenarios/blocks/*.json`을 `include`로 재사용한다
(login/module_open/lookup_popup/file_dialog 등). 새 시나리오는 **블록 재사용을 먼저 검토**한다.

## 절대 틀리면 안 되는 규칙 (반복된 버그의 원인)

- **`--vars`는 콤마로 구분된 "단일 문자열 인자"** 다. PowerShell 배열을 `--vars @arr`로 splat하거나 `--vars A B`처럼 공백 토큰으로 넘기면 **첫 변수만 파싱**되고 나머지는 `${WO_NO}` 같은 리터럴로 남는다. 반드시 `($pairs -join ',')`로 하나의 문자열로 합쳐 넘긴다.
- **값에 콤마가 있는 변수**(예: `MEAL_DATES=2026-05-21,2026-05-22`)는 `--vars`에 넣지 말고 `$env:`로 주입한다(CLI가 환경변수도 자동 주입). 콤마가 구분자로 오인되기 때문.
- PowerShell 자동변수 `$PWD`(현재 디렉터리)와 충돌하므로 비밀번호 변수는 `$ErpPwd` 등 **다른 이름**을 쓴다.
- 사용자 시나리오 실행 시 블록 include 해석을 위해 `$env:ERPCTRL_BLOCKS_DIR = "$env:APPDATA\erpctrl\scenarios\blocks"`를 설정한다.
- 공유서버 접근 불가(VPN/오프라인) 시 **대체 경로 없이 즉시 중단**하고 원인을 안내한다.

종료 코드: `0` 성공 / `2` 시나리오 실패 / `3` 컨트롤 식별 실패 / `4` 프로세스 기동 실패 / `5` 사용자 중단(ESC).

## 이 저장소를 수정할 때

- 이 저장소 편집은 거의 항상 **SKILL.md / README.md / 매니페스트의 문구·절차 수정**이다. 스킬과 README의 절차·변수 표·실행 스니펫은 서로 일관되게 유지한다(특히 위의 `--vars` 규칙).
- 사용자 인터페이스 텍스트는 한국어다. **한글 깨짐(mojibake) 방지**가 중요하다 — 파일은 UTF-8로 쓰고, 작성 후 한글이 온전한지 읽어 확인한다.
- 버전을 올릴 때 `.claude-plugin/plugin.json`과 `.codex-plugin/plugin.json`의 `version`을 함께 갱신한다.
- Codex 유지보수 지침은 루트 `AGENTS.md`에도 반영한다.

## 문서화 컨벤션 (이 저장소가 따르는 규칙)

코드를 변경하면 `docs/`에 이력을 남긴다. 두 인덱스를 먼저 읽어 맥락을 파악한다:

- `docs/plan_history.md` — 계획 인덱스. 상세는 `docs/plans/PLAN-YYYY-NNN_*.md`.
- `docs/revision_history.md` — 변경 이력 인덱스. 상세는 `docs/revisions/*.md`.

새 계획/변경은 각 인덱스에 한 줄을 추가하고 대응 상세 파일을 만든다. (이 워크플로우는 사용자의
`plan-context`·`revision-tracker` 스킬과 연동된다.)

## 설치 (참고)

Claude Code:

```
/plugin marketplace add Donghun1q2w/ERPctrl   # 또는 로컬 경로
/plugin install erpctrl@erpctrl
```

Codex:

```
codex plugin marketplace add <marketplace-root>
codex plugin add erpctrl@<marketplace-name>
```

상세한 Codex 로컬 마켓플레이스 구조와 검증 명령은 `README.md`를 따른다.
이 저장소는 Claude Code용 `.claude-plugin/marketplace.json`과 Codex용 `.codex-plugin/plugin.json`을 포함한다.
