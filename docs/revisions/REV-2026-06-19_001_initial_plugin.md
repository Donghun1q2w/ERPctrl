# REV-2026-06-19-001 — erpctrl 플러그인 초기 구현

- **일시**: 2026-06-19
- **관련 계획**: [PLAN-2026-001](../plans/PLAN-2026-001_erpctrl_plugin.md)
- **유형**: 신규 (greenfield)

## 변경 파일

| 파일 | 내용 |
|---|---|
| `.claude-plugin/plugin.json` | 플러그인 매니페스트 (name `erpctrl`, v0.1.0) |
| `.claude-plugin/marketplace.json` | 자기참조 마켓플레이스 (source `./`) |
| `skills/erpctrl/SKILL.md` | 실행기: 부트스트랩 → update → 시나리오 매칭 → 변수 해석 → run |
| `skills/erpctrl-scenario/SKILL.md` | 생성기: analyze/discover → 블록 재사용 → my_scenarios 저장 → 검증 |
| `README.md` | 설치/사용/동작원리 |
| `.gitignore` | `*.exe`·`*.dll`·`*.pdb` 차단 (바이너리 미번들) |
| `docs/plans/`, `docs/plan_history.md` | 계획 문서/인덱스 |

## 설계 결정

- CLI 바이너리 미번들 → 실행 시 공유서버(`Z:\...\ErpCtrl`)에서 `%APPDATA%\erpctrl\`로 부트스트랩.
- 배치: 최초 robocopy 후 exe `update`로 동기화 위임.
- Fallback: 주 경로만, 실패 시 중단.
- 시나리오 생성: `%APPDATA%\erpctrl\my_scenarios\`에만 저장(update 미러 보호).
- 민감변수: 환경변수 우선, PWD 미설정 시 실행 시점 입력(저장·로그 금지).

## 검증

- `plugin.json`/`marketplace.json` `ConvertFrom-Json` 통과.
- 두 SKILL.md frontmatter(`---`/`name`/`description`) 확인.
- 시나리오 매칭 PowerShell을 공유서버 실데이터로 실행 → id/description 정상 추출, 한글 무결성 확인(mojibake 없음).
- `git init` + 원격 `git@github.com:Donghun1q2w/ERPctrl.git` 등록, staged 트리에 바이너리 없음 확인.
