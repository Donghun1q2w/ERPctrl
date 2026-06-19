# REV-2026-06-19-002 — 스킬 실행 전 README.md 필수 숙지

- **일시**: 2026-06-19
- **관련 계획**: [PLAN-2026-002](../plans/PLAN-2026-002_readme_first.md)
- **유형**: 보완

## 변경 파일

| 파일 | 내용 |
|---|---|
| `skills/erpctrl/SKILL.md` | 상단 필수 안내 + `Step 1.5 — README 숙지(필수)` 신설 (Read 후 매칭/실행) |
| `skills/erpctrl-scenario/SKILL.md` | 상단 필수 안내 + `Step 1.5 — README 숙지(필수)` 신설 (작성 전 액션/블록/가이드 확인) |

## 동작

- 부트스트랩/`update` 직후 `%APPDATA%\erpctrl\README.md`(폴백: 공유서버 README)를 Read로 숙지.
- README 부재 시 사용자 보고·중단.
- SKILL.md 요약과 README가 다르면 **README 우선**(서버 최신 반영).

## 검증

- README 폴백 PowerShell 스니펫 실행 → `%APPDATA%\erpctrl\README.md` 해석·실존 확인, 첫 줄 한글 정상.
- 두 SKILL.md frontmatter 무손상 + `Step 1.5` 삽입 확인.
