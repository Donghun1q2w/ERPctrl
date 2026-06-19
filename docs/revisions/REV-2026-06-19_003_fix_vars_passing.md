# REV-2026-06-19-003 — --vars 변수 전달 버그 수정

- **일시**: 2026-06-19
- **관련 계획**: [PLAN-2026-003](../plans/PLAN-2026-003_fix_vars_passing.md)
- **유형**: 버그 수정

## 증상

시나리오 실행 시 `WO_NO`/`SAVE_DIR` 등이 치환되지 않고 `${WO_NO}` 리터럴로 남음.
(실제 흔적: `D:\tmp\${WO_NO}-Spoolbom_Item_List.xlsx`)

## 근본 원인 (소스 확인 `src/Erpctrl.Cli/Program.cs`)

- `--vars`는 바로 뒤 인자 **하나만** 소비(`args[++i]`).
- `ParseVars`가 그 하나를 **콤마(`,`)로 분리**하여 `KEY=VAL` 파싱.
- 스킬은 `--vars @vars`(PowerShell 배열 splat = 공백 구분 다중 토큰)로 전달 → **첫 변수만** 파싱.
- USER_ID/PWD/SHERP_EXE_PATH는 환경변수로도 주입되어 우연히 동작, 환경변수에 없던 WO_NO/SAVE_DIR만 미치환.

## 변경 파일

| 파일 | 내용 |
|---|---|
| `skills/erpctrl/SKILL.md` | Step 4 실행 스니펫: `--vars ($varList -join ',')` 콤마-join + 콤마 값 자동 환경변수 전환 + 경고 박스 |
| `skills/erpctrl-scenario/SKILL.md` | Step 6 검증 스니펫 동일 패턴 적용 |
| `README.md` | 동작원리 실행 예시를 콤마-구분 단일 인자로 정정 |

## 검증 (실측)

- (A) 공백 splat `--vars "WO_NO=.." "SAVE_DIR=.."` → `'${SAVE_DIR}/P250129-01-OK'` (SAVE_DIR 미치환, 버그 재현).
- (B) 콤마-join `--vars "WO_NO=..,SAVE_DIR=.."` → `'D:\tmp\testerp/P250129-01-OK'` (전부 치환).
- (C) 수정 스니펫 로직(콤마 값 MEAL_DATES 자동 환경변수 전환) → `'D:\tmp\testerp/P250129-01/2026-05-21,2026-05-22-OK'` (세 변수 모두 치환).
- 검증용 임시 시나리오/디렉터리 정리 완료.
