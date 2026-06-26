# Codex Cross-Compatible Plugin Support

- **Date**: 2026-06-26 13:50:19
- **Status**: Completed

## Summary

현재 erpctrl 플러그인은 Claude Code용 `.claude-plugin` 매니페스트와 공용 `skills/`만 갖고 있어 Claude Code에서는 설치 가능한 형태지만, Codex 네이티브 플러그인으로는 `.codex-plugin/plugin.json`이 없어 독립 검증과 설치 안내가 부족하다. 이 계획은 기존 Claude 사용성을 유지하면서 Codex에서도 같은 스킬을 로드할 수 있도록 패키지 메타데이터와 문서를 보강한다.

## Background

분석 결과 `skills/erpctrl/SKILL.md`와 `skills/erpctrl-scenario/SKILL.md`는 Codex에서도 재사용 가능한 Markdown 스킬 형식이다. 부족한 부분은 Codex 플러그인 매니페스트, Codex 설치 흐름 설명, 그리고 저장소 유지보수 지침의 Claude 전용 표현이다.

## Proposal

1. `.codex-plugin/plugin.json`을 추가해 Codex 플러그인 수집기가 `skills/`를 명시적으로 로드할 수 있게 한다.
2. `.claude-plugin/plugin.json`과 `.claude-plugin/marketplace.json`의 설명과 버전을 갱신해 이 패키지가 Claude Code와 Codex를 모두 지원함을 표시한다.
3. `README.md`에 호환성 현황, Claude Code 설치 명령, Codex 설치 명령/마켓플레이스 구조, 검증 명령을 분리해 적는다.
4. `AGENTS.md`를 추가해 Codex가 이 저장소를 수정할 때 CLI 바이너리 미번들, UTF-8, `--vars` 단일 인자 규칙을 놓치지 않도록 한다.
5. Codex 플러그인 검증 스크립트와 JSON/YAML 파싱으로 매니페스트와 스킬 frontmatter를 확인한다.

## Acceptance Criteria

- Before: 저장소에는 `.claude-plugin/`만 있고 README는 Claude Code 설치만 안내한다.
- After:
  - `.codex-plugin/plugin.json`이 존재하고 `name`, `version`, `description`, `author`, `skills`, `interface` 필드를 Codex 검증 규칙에 맞게 포함한다.
  - 기존 `.claude-plugin/` 구조와 `skills/` 경로는 유지된다.
  - README에서 Claude Code와 Codex 설치/검증 경로가 분리되어 재현 가능하다.
  - Codex 검증 스크립트가 플러그인 루트에서 통과한다.
  - JSON 매니페스트와 두 SKILL.md frontmatter가 UTF-8로 정상 파싱된다.

## Impact

| Area | Description |
|------|-------------|
| Files | `.codex-plugin/plugin.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/plan_history.md` |
| Dependencies | 신규 런타임 의존성 없음. 검증은 기존 Codex `plugin-creator` 스크립트 사용 |
| Risk | Codex 마켓플레이스 등록 구조가 사용자 환경마다 다를 수 있어 README는 표준 `plugins/erpctrl` 구조와 명령을 명시한다 |

## Verification Steps

1. `python C:\Users\donghun.lee\.codex\skills\.system\plugin-creator\scripts\validate_plugin.py .`
2. PowerShell `ConvertFrom-Json`으로 `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json` 파싱 확인.
3. Python UTF-8 + YAML 파싱으로 `skills/**/SKILL.md` frontmatter 확인.
4. `git diff --stat`으로 변경 범위 확인.
