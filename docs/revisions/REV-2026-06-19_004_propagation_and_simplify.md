# REV-2026-06-19-004 — 실행 스니펫 단순화 + 설치본 전파 수정

- **일시**: 2026-06-19
- **관련 계획**: [PLAN-2026-003](../plans/PLAN-2026-003_fix_vars_passing.md) (후속)
- **유형**: 버그 수정 (전파 누락) + 단순화

## 문제

REV-003에서 `--vars`를 콤마-join으로 고쳤으나 **여전히 `${WO_NO}` 리터럴 발생("개선 안 됨")**.

근본 원인: 플러그인은 **설치 캐시본**(`~/.claude/plugins/cache/erpctrl/erpctrl/0.1.0`)에서 실행되며,
이는 최초 설치 commit `46ca01b`(수정 前)에 고정. repo 수정이 런타임에 전파되지 않음.
캐시본 SKILL.md에 구버전 `--vars @vars`가 그대로 남아 있었음.

## 변경

| 파일 | 내용 |
|---|---|
| `skills/erpctrl/SKILL.md` | Step 4 실행 스니펫을 검증된 `tools/run_spool_progress.ps1` line 393 패턴(`$varsArg="K1=V1,K2=V2,..."` 단일 문자열)으로 단순화. 배열 splat 금지 명시 |
| `skills/erpctrl-scenario/SKILL.md` | Step 6 동일 패턴으로 통일 |
| `.claude-plugin/plugin.json` | version 0.1.0 → 0.1.1 |
| (설치본 전파) | `~/.claude/plugins/cache/.../0.1.0` 및 `marketplaces/erpctrl` 클론의 skills를 repo 최신본으로 직접 동기화 |

## 검증

- 콤마-join 단일 문자열로 `${WO_NO}`/`${SAVE_DIR}` 정상 치환(REV-003 (B)/(C)에서 실측).
- 캐시본 SKILL.md에서 `--vars @vars` 제거, `$varsArg` 단일 문자열 패턴 반영 확인.

## 사용자 후속 (권장)

깨끗한 상태 유지를 위해 다음으로 0.1.1 정식 갱신:
```
/plugin marketplace update erpctrl
/plugin update erpctrl@erpctrl
```
