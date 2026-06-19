# PLAN-2026-003: --vars 변수 전달 버그 수정

- **상태**: Pending (사용자 검토 대기)
- **작성일**: 2026-06-19
- **유형**: 버그 수정
- **대상**: `skills/erpctrl/SKILL.md`, `skills/erpctrl-scenario/SKILL.md`

## 1. 증상

시나리오 실행 시 `WO_NO`/`SAVE_DIR` 등이 치환되지 않고 `${WO_NO}` 리터럴로 남음.

## 2. 근본 원인 (소스 확인)

`src/Erpctrl.Cli/Program.cs`:
- `--vars`는 **바로 뒤 인자 하나만** 소비(`args[++i]`).
- `ParseVars`는 그 하나를 **콤마(`,`)로 분리**하여 `KEY=VAL` 파싱.
- 즉 올바른 사용법: `--vars "USER_ID=x,PWD=y,WO_NO=z,SAVE_DIR=..."` (콤마 구분 단일 인자).

스킬은 `--vars @vars`(PowerShell 배열 splat = 공백 구분 다중 토큰)으로 전달 →
`--vars`가 **첫 토큰만** 파싱, 나머지는 무시. 환경변수로도 주입되는 변수(USER_ID/PWD/SHERP_EXE_PATH)는
우연히 동작했으나, 환경변수에 없는 `WO_NO`/`SAVE_DIR`은 미해석되어 리터럴로 남음.

추가 제약: `--vars`는 콤마 구분이므로 **값에 콤마가 포함된 변수(예: MEAL_DATES="...,...")는 `--vars`로 전달 불가** → 환경변수로 주입해야 함.

## 3. 수정 방안

두 SKILL.md의 실행 스니펫을 다음과 같이 변경:

1. **`--vars`는 콤마-join 단일 인자**로 전달:
   ```powershell
   $varPairs = @("USER_ID=$env:USER_ID", "PWD=$ErpPwd", "WO_NO=$WoNo", "SAVE_DIR=$SaveDir")
   & $exe run --scenario $scenario --vars ($varPairs -join ',')
   ```
2. **콤마 포함 값은 `--vars` 금지, 환경변수 사용** 명시(MEAL_DATES 등):
   ```powershell
   $env:MEAL_DATES = "2026-05-21,2026-05-22"   # --vars 대신 환경변수
   ```
3. PWD는 콤마/특수문자 가능성 → 콤마 없으면 `--vars`, 있으면 `$env:PWD`로 안내.
4. 변수값에 콤마가 있으면 자동으로 환경변수로 돌리도록 스니펫에 분기 주석 추가.
5. erpctrl-scenario Step 6 검증 스니펫도 동일 패턴으로 수정.

## 4. Acceptance Criteria

- **Before**: `--vars @vars`(공백 토큰) → 첫 변수만 파싱, `${WO_NO}` 리터럴.
- **After**:
  - [ ] 두 SKILL.md 실행 스니펫이 `--vars ($pairs -join ',')` 단일 인자 형태.
  - [ ] 콤마 포함 값은 환경변수로 주입하도록 명시.
  - [ ] WO_NO/SAVE_DIR 포함 모든 변수가 정상 치환됨(검증).

## 5. 검증

- 임시 시나리오로 `${WO_NO}`/`${SAVE_DIR}` 치환을 실제 CLI로 확인(SHIIS 불요한 smoke 형태로 echo/mkdir 활용).
