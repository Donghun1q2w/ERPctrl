# Revision 2026-06-19 14:29:25 — erpctrl SKILL.md 변수 표 정리 (수동)

## Summary

`skills/erpctrl/SKILL.md` Step 3 변수 표에서 시나리오별 변수 3행을 제거 (사용자 수동 수정 반영).

## Rationale / Plan

- 사용자가 직접 SKILL.md를 수정. Step 3 변수 표에는 공통 변수(`USER_ID`, `PWD`, `SHERP_EXE_PATH`, `SHERP_MAIN_EXE_PATH`)만 남기고,
  시나리오별 변수(`WO_NO`, `SAVE_DIR`, 식수관리 변수)는 표에서 삭제.
- Step 1.5의 **"README 우선" 원칙**과 일치 — 시나리오별 필수 변수는 각 시나리오 `description` 및 `README.md`의
  변수 레퍼런스를 권위 있는 출처로 삼고, SKILL.md 표는 공통 변수만 간결하게 유지.
- 변경 후 배포(설치 캐시본 + 마켓플레이스 클론 동기화)까지 수행.

## Changed Files

| 파일 | 상태 | 설명 |
|---|---|---|
| `skills/erpctrl/SKILL.md` | modified | Step 3 변수 표에서 WO_NO/SAVE_DIR/식수관리 행 제거 |

## Details

- `skills/erpctrl/SKILL.md` (Step 3 — 변수 해석):
  - 제거된 행:
    - `WO_NO` | 작업지시 번호 (spool 계열) | 사용자 입력
    - `SAVE_DIR` | 엑셀 저장 폴더 | 사용자 입력(기본 제안 가능)
    - `SITE_NAME/DEPT_NAME/MEAL_DATES/DEPT_COUNT/BREAKFAST/LUNCH/DINNER` | 식수관리 | 사용자 입력
  - 유지된 공통 변수: `USER_ID`, `PWD`, `SHERP_EXE_PATH`, `SHERP_MAIN_EXE_PATH`.
  - Step 4 실행 스니펫(콤마-join 단일 문자열)·Step 1.5(README 우선)는 변경 없음.

## 배포

- 커밋 후 `~/.claude/plugins/cache/erpctrl/erpctrl/0.1.0/skills` 및 `~/.claude/plugins/marketplaces/erpctrl/skills`로 동기화.
