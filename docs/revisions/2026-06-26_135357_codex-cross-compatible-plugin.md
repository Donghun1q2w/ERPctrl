# Codex 플러그인 호환성 보강

- **Date**: 2026-06-26 13:53:56
- **Author**: Codex

## Rationale / Plan

사용자가 현재 erpctrl 플러그인이 Claude 기반인데 Codex와 크로스 사용 가능한지 확인하고 개선해 달라고 요청했다. 확인 결과 공용 `skills/`는 Codex에서도 재사용 가능한 구조였지만, Codex 네이티브 `.codex-plugin/plugin.json`이 없고 README/저장소 지침이 Claude Code 중심으로 작성되어 있어 Codex 설치와 유지보수 재현성이 부족했다.

계획은 `docs/plans/2026-06-26_135019_codex-cross-compatible-plugin.md`에 기록했고, 기존 Claude Code 사용성을 유지한 채 Codex 매니페스트와 문서만 추가/보강했다.

## Changed Files

| File | Status | Description |
|------|--------|-------------|
| `.codex-plugin/plugin.json` | Added | Codex 플러그인 매니페스트 추가 |
| `.claude-plugin/plugin.json` | Modified | 버전 `0.2.0` 및 Claude Code/Codex 겸용 설명 반영 |
| `.claude-plugin/marketplace.json` | Modified | 공용 skills 포함 설명 추가 |
| `README.md` | Modified | 호환성 표, Claude Code/Codex 설치 절차, Codex 검증 명령 추가 |
| `AGENTS.md` | Added | Codex용 저장소 유지보수 지침 추가 |
| `CLAUDE.md` | Added/Modified | Claude Code 지침을 듀얼 플러그인 구조에 맞게 갱신 |
| `docs/plans/2026-06-26_135019_codex-cross-compatible-plugin.md` | Added | 구현 계획 문서 추가 |
| `docs/plan_history.md` | Modified | 신규 계획 상태 기록 및 완료 처리 |
| `docs/revision_history.md` | Modified | 이번 변경 이력 인덱스 추가 |
| `docs/revisions/2026-06-26_135357_codex-cross-compatible-plugin.md` | Added | 이번 변경 상세 기록 |

## Details

### `.codex-plugin/plugin.json` (Added)

- Codex 검증 규격에 맞춰 `name`, `version`, `description`, `author`, `skills`, `interface` 필드를 작성했다.
- `skills`는 기존 공용 `./skills/`를 가리키도록 설정했다.
- 기본 프롬프트와 UI 설명은 한국어 ERP 자동화 용례에 맞춰 작성했다.

### `.claude-plugin/plugin.json` (Modified)

- 버전을 `0.1.1`에서 `0.2.0`으로 올렸다.
- 설명을 Claude Code 전용에서 Claude Code/Codex 겸용으로 변경했다.

### `.claude-plugin/marketplace.json` (Modified)

- 마켓플레이스 설명에 Claude Code와 Codex가 공용 `skills/`를 사용한다는 내용을 추가했다.

### `README.md` (Modified)

- 제목과 소개를 Claude Code / Codex 겸용 플러그인으로 갱신했다.
- Claude Code와 Codex의 매니페스트, 설치 명령, 런타임 공통점을 표로 정리했다.
- Codex 로컬 마켓플레이스 표준 구조와 `codex plugin marketplace add`, `codex plugin add` 설치 명령을 추가했다.
- Codex `plugin-creator` 검증 스크립트 실행 예시를 추가했다.

### `AGENTS.md` (Added)

- Codex가 이 저장소를 수정할 때 필요한 구조 설명과 런타임 불변 규칙을 기록했다.
- CLI 바이너리 미번들, UTF-8, README-first, `--vars` 단일 문자열 인자, 비밀번호 비노출 규칙을 명시했다.

### `CLAUDE.md` (Added/Modified)

- 기존 Claude Code 지침을 듀얼 플러그인 저장소 설명으로 갱신했다.
- Codex 유지보수 지침은 `AGENTS.md`에도 반영해야 함을 추가했다.
- Codex 설치 명령은 README의 상세 구조를 따르도록 연결했다.

### Documentation (Added/Modified)

- `docs/plans/2026-06-26_135019_codex-cross-compatible-plugin.md`에 계획과 검증 기준을 기록했다.
- `docs/plan_history.md`의 신규 계획 상태를 완료로 갱신했다.
- `docs/revision_history.md`에 이번 변경 이력을 추가했다.

## Verification

- `python C:\Users\donghun.lee\.codex\skills\.system\plugin-creator\scripts\validate_plugin.py .` 통과.
- `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` 모두 PowerShell `ConvertFrom-Json` 파싱 성공.
- `rg`로 README/CLAUDE/AGENTS/매니페스트의 Claude Code/Codex 관련 문구 반영 확인.
