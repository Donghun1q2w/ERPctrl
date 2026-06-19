# erpctrl — Claude Code 플러그인

SHIIS3 ERP UI 자동화 CLI(`erpctrl.exe`)를 **자연어로 구동**하는 Claude Code 플러그인.

CLI 바이너리는 이 저장소에 포함되지 않는다. 스킬 실행 시 공유서버에 배포된 CLI를
`%APPDATA%\erpctrl\`로 부트스트랩한 뒤 사용한다.

## 제공 스킬

| 스킬 | 용도 |
|---|---|
| `erpctrl` | 자연어 지시 → 가장 유사한 시나리오 매칭 → CLI 실행 |
| `erpctrl-scenario` | 새 시나리오(JSON) 작성 → `%APPDATA%\erpctrl\my_scenarios\`에 저장 |

## 사전 조건

- Windows + PowerShell
- 공유서버 접근: `Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\`
  (네트워크 드라이브 `Z:` 매핑 / 사내망·VPN). **접근 불가 시 스킬은 중단된다.**
- SHIIS3 설치 경로 환경변수(권장, 한 번만):
  ```powershell
  [System.Environment]::SetEnvironmentVariable("SHERP_EXE_PATH","C:\SHIIS3\shERP.exe","User")
  [System.Environment]::SetEnvironmentVariable("SHERP_MAIN_EXE_PATH","C:\SHIIS3\shERP_main.exe","User")
  ```

## 설치

이 저장소는 자기 자신을 가리키는 마켓플레이스를 포함한다.

```
/plugin marketplace add Donghun1q2w/ERPctrl
/plugin install erpctrl@erpctrl
```

또는 로컬 경로로:

```
/plugin marketplace add D:\001_Work\2026\040_ERP_Ctrl\erpctrl_plugin
/plugin install erpctrl@erpctrl
```

## 사용 예

### 시나리오 실행 (`erpctrl`)

```
자재코드를 대분류별로 엑셀로 받아줘
```
→ `matlcode_search_by_category` 시나리오로 매칭, 필요한 변수(USER_ID/PWD/SAVE_DIR 등)를
환경변수에서 읽거나 입력받아 실행.

```
W/O 12345로 spool 진행 엑셀 일괄 다운로드
```
→ `spool_progress_v2` 매칭.

### 시나리오 생성 (`erpctrl-scenario`)

```
구매 > 거래처 등록 화면을 자동화하는 시나리오 만들어줘
```
→ `analyze`/`discover`로 컨트롤 확보 → 블록 재사용 → `my_scenarios\`에 저장 → 검증.

## 동작 원리

1. **부트스트랩**: `%APPDATA%\erpctrl\erpctrl.exe`가 없으면 공유서버에서 최초 1회 복사(약 82MB).
2. **동기화**: 이후 `erpctrl update`로 `scenarios/`·`controls/`를 서버 기준 최신화.
3. **매칭**: 각 시나리오 JSON의 한글 `description`을 자연어 요청과 의미 비교.
4. **변수**: 환경변수 우선, `PWD`는 미설정 시 실행 시점 입력(저장·로그 노출 없음).
5. **실행**: `erpctrl run --scenario <경로> --vars K=V ...`.

## 주의

- 사용자 작성 시나리오는 `my_scenarios\`에 둔다. `scenarios\`는 `update` 시 서버 기준 미러로 삭제된다.
- 실행 중 **ESC**로 안전 중단.
- 종료 코드: `0` 성공 / `2` 시나리오 실패 / `3` 컨트롤 식별 실패 / `4` 프로세스 기동 실패 / `5` 사용자 중단.

## 관련 저장소

- CLI 본체: `ERP_Remote_Control` (성화산업 SHIIS3 제어 .NET 8 프레임워크) — 이 플러그인에는 미포함.
