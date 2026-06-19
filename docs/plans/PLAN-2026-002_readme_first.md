# PLAN-2026-002: 스킬 실행 전 erpctrl README.md 필수 숙지

- **상태**: Pending (사용자 검토 대기)
- **작성일**: 2026-06-19
- **작성자**: dh-dev orchestrator
- **대상**: `skills/erpctrl/SKILL.md`, `skills/erpctrl-scenario/SKILL.md`
- **선행 계획**: [PLAN-2026-001](PLAN-2026-001_erpctrl_plugin.md)

## 1. 목표

두 스킬이 실제 작업(시나리오 매칭·실행·작성)을 수행하기 **전에 반드시 `erpctrl`의 `README.md`를
먼저 읽고 숙지**하도록 워크플로우를 보완한다. README에는 시나리오 표·변수 레퍼런스·액션
레퍼런스·트러블슈팅·블록 카탈로그가 권위 있게 정리되어 있어, 이를 근거로 동작 정확도를 높인다.

## 2. 배경

- `README.md`는 부트스트랩/`update` 후 `%APPDATA%\erpctrl\README.md`에 위치(최신본). 공유서버
  `Z:\...\ErpCtrl\README.md`에도 존재.
- 현재 스킬은 README를 명시적으로 읽지 않고 SKILL.md에 요약된 정보에만 의존 → 서버에 새 시나리오/
  액션/주의사항이 추가되면 누락 위험.

## 3. 구현 단계

1. **`skills/erpctrl/SKILL.md`**
   - 상단 안내 블록에 "**실행 전 반드시 README.md 숙지**" 1줄 추가.
   - `Step 1`(부트스트랩) 직후, `Step 2`(시나리오 매칭) 앞에 **`Step 1.5 — README 숙지 (필수)`** 신설:
     - `%APPDATA%\erpctrl\README.md`를 Read로 읽어 시나리오 표·변수표·액션·주의사항을 내재화.
     - 파일이 없으면(부트스트랩 직후 동기화 실패 등) 공유서버 README로 폴백, 그것도 없으면 사용자에게 보고.
2. **`skills/erpctrl-scenario/SKILL.md`**
   - 상단 안내 + `Step 1`(CLI 준비) 직후 **README 숙지 필수 스텝** 추가(특히 액션 레퍼런스·블록 카탈로그·트러블슈팅 확인).
3. **문서 갱신**: revision 기록, plan_history/ revision_history 인덱스 갱신.

## 4. Acceptance Criteria

- **Before**: 스킬이 README를 읽지 않고 SKILL.md 요약에만 의존.
- **After**:
  - [ ] 두 SKILL.md 모두 본문 작업 전 `%APPDATA%\erpctrl\README.md`(폴백: 공유서버)를 Read하도록 **필수 스텝**으로 명시.
  - [ ] README 부재 시 폴백/보고 동작이 명시됨.
  - [ ] 기존 절차(부트스트랩/매칭/실행/생성)와 모순 없이 자연스럽게 삽입됨.

## 5. 리스크

- 단계 번호 삽입(1.5)으로 후속 참조 혼란 최소화 — 기존 Step 2~5 번호는 유지.
