    사급 자재 현황(SUBCONTRACT_ITEM_LIST) → SHIIS 종료. vars: USER_ID, PWD, SHERP_EXE_PATH, WO_NO, SAVE_DIR."
       },
       {
         "id": "spool_progress_v2",
         "file": "C:\\Users\\donghun.lee\\AppData\\Roaming\\erpctrl\\scenarios\\spool_progress_v2.json",
         "description": "PLAN-2026-011 마이그레이션 + 6개 모듈 일괄 다운로드. 흐름: 로그인 → ①공정별 완료(OPERDATE_OPER_ITEM) → ②작업지시서 현황(ORDER_STATUS_LIST) → ③PIPE SPOOL
     CUTTING 입력[협력] 진행 Project Pipe BOM(Spoolbom_Item_List) → ④SPOOL DRAWING BOM/JOINT(PPG_DRAWING_MBOM_LIST/JOINT_LIST) → ⑤MAT'L TRACKING LIST(MATL_TRACKING_LIST) → ⑥W/O별
     사급 자재 현황(SUBCONTRACT_ITEM_LIST) → SHIIS 종료. vars: USER_ID, PWD, SHERP_EXE_PATH, WO_NO, SAVE_DIR."
       },
       {
         "id": "spool_progress",
         "file": "C:\\Users\\donghun.lee\\AppData\\Roaming\\erpctrl\\scenarios\\spool_progress.json",
         "description": "shERP_main 로그인 → 생산 > 생산 실적 > PIPING 부문 > 공정별 완료일 현황 모듈(coerp_mfg_operdate_oper.exe) 진입 → W/O 검색 → 첫 row 진입 → SPOOL별 공정완료일
     탭으로 이동 → Download 클릭 후 SaveFileDialog에 '${SAVE_DIR}\\${WO_NO}-OPERDATE_OPER_ITEM.xlsx' 저장. vars: USER_ID, PWD, SHERP_EXE_PATH, WO_NO, SAVE_DIR."
       }
     ]
  ⎿  3 PostToolUse hooks ran

                                                                                                                                                          01:59 PM claude-opus-4-8
● spool_bom_progress 시나리오가 요청("spool bom 추출")과 일치합니다. 변수 해석을 위해 환경변수를 확인합니다.

● PowerShell("USER_ID         = " + ($(if($env:USER_ID){$env:USER_ID}else{'(없음)'}))
            "SHERP_EXE_PATH  = " + ($(if($env:SHERP_EXE_PATH){$env:SHERP_EXE_PATH}else{'(없음)'}))
            "SHERP_MAIN_EXE  = " + ($(if($env:SHERP_MAIN_EXE_PATH){$env:SHERP_MAIN_EXE_PATH}else{'(없음)'}))
            "PWD(env)        = " + ($(if($env:PWD){'(설정됨)'}else{'(없음)'})))
  ⎿  USER_ID         = S20061101
     SHERP_EXE_PATH  = C:\Seonghwa\SHIIS3\shERP.exe
     SHERP_MAIN_EXE  = C:\seonghwa\SHIIS3\shERP_main.exe
     PWD(env)        = (설정됨)
  ⎿  3 PostToolUse hooks ran

                                                                                                                                                          01:59 PM claude-opus-4-8
● 모든 변수 준비 완료:
  - USER_ID = S20061101
  - PWD = 환경변수에 설정됨
  - SHERP_EXE_PATH = C:\Seonghwa\SHIIS3\shERP.exe
  - WO_NO = P250129-01
  - SAVE_DIR = D:\tmp\testerp (현재 프로젝트)

  시나리오를 실행합니다. (실행 중 ESC로 안전 중단 가능)

● PowerShell($dst = Join-Path $env:APPDATA 'erpctrl'
            $exe = Join-Path $dst 'erpctrl.exe'
            $scenario = Join-Path $dst 'scenarios\spool_bom_progress.json'
            $env:ERPCTRL_BLOCKS_DIR = Join-Path $dst 'scenarios\blocks'
            $ErpPwd = $env:PWD

            $vars = @(
                "USER_ID=$env:USER_ID",
                "PWD=$ErpPwd",
                "SHERP_EXE_PATH=$env:SHERP_EXE_PATH",
                "WO_NO=P250129-01",
                "SAVE_DIR=D:\tmp\testerp"
            )

            & $exe run --scenario $scenario --vars @vars
            "exit code: $LASTEXITCODE")
  ⎿  Error: Exit code 5
     [13:59:32 INF] running scenario 'spool_bom_progress' (18 steps) - logs at Z:\그룹 공유\R&D\연구개발부\Common\011. 편리한 프로그램\ErpCtrl\logs\donghun.lee\20260619_135932_c179fa
     [server] (ESC=긴급 정지)
     [13:59:32 INF] step 1 mkdir value=D:\tmp
     [13:59:32 INF]   step 1 -> ensured directory 'D:\tmp' (7ms)
     [13:59:32 INF] step 2 include value=blocks/login_sherp.json
     [13:59:32 INF]   inner step 1 launch value=C:\Seonghwa\SHIIS3\shERP.exe (from block 'login_sherp')
     [13:59:35 INF]     -> launched pid=78372 window='coEIS' (2720ms)
     [13:59:35 INF]   inner step 2 switchWindow target=coEIS (from block 'login_sherp')
     [13:59:42 INF]     -> scope='coEIS' (7637ms)
     [13:59:42 INF]   inner step 3 waitEnabled target=btnStart (from block 'login_sherp')
     [13:59:43 INF]     -> enabled='btnStart' (848ms)
     [13:59:43 INF]   inner step 4 click target=btnStart (from block 'login_sherp')
     [13:59:44 INF]     -> clicked (physical) (193ms)
     [13:59:44 INF]   inner step 5 attachApp target=Sign In (from block 'login_sherp')
     [14:00:00 INF]     -> attached pid=78080 window='Sign In' (16930ms)
     [14:00:00 INF]   inner step 6 setText target=txtUseridno value=S20061101 (from block 'login_sherp')
     [14:00:01 INF]     -> set='S20061101' (659ms)
     [14:00:01 INF]   inner step 7 setText target=txtPassword value=(masked) (from block 'login_sherp')
     [14:00:01 INF]     -> set (masked) (93ms)
     [14:00:01 INF]   inner step 8 click target=btnLogin (from block 'login_sherp')
     [14:00:06 INF]     -> clicked (4394ms)
     [14:00:06 INF]   inner step 9 switchWindow target=SHIIS (from block 'login_sherp')
     [14:00:15 INF]     -> scope='SHIIS Ver.3.0 [강구재]' (9095ms)
     [14:00:15 INF]   step 2 -> included 'login_sherp' from 'C:\Users\donghun.lee\AppData\Roaming\erpctrl\scenarios\blocks\login_sherp.json' (9 steps) (42585ms)
     [14:00:15 INF] step 3 include value=blocks/module_open.json
     [14:00:15 INF]   inner step 1 openMenu target=협력 > 등록 > PIPE SPOOL CUTTING 입력[협력] (from block 'module_open')
     [14:00:18 INF]     -> opened menu='협력 > 등록 > PIPE SPOOL CUTTING 입력[협력]' (2965ms)
     [14:00:18 INF]   inner step 2 sleep value=2000 (from block 'module_open')