---
name: logzine-run
description: LOGZINE 앱 실행 방법과 에뮬레이터·빌드 문제 해결. 앱이 실행되지 않거나 에뮬레이터가 죽을 때 이 문서대로 진단한다.
---

# LOGZINE 실행 & 트러블슈팅

## 기본 실행

```bash
cd logzine_app
flutter pub get
flutter run -d chrome     # 가장 빠른 확인 (F12 → Ctrl+Shift+M → iPhone 프리셋)
```

## 안드로이드 에뮬레이터 (Windows) — ⚠️ 반드시 이 방식으로

```powershell
# 에뮬레이터는 소프트웨어 GPU로 실행 (기본 GPU 모드는 앱 렌더링 시 에뮬레이터가 통째로 죽음)
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone -gpu swiftshader_indirect

# 부팅 완료 후
flutter run --no-enable-impeller
```

- ❌ `flutter emulators --launch`(기본 GPU 모드) 사용 금지
- 실행 중 단축키: `r` 핫 리로드 · `R` 재시작 · `q` 종료

## 증상별 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| 앱이 뜨는 순간 에뮬레이터 통째로 종료 | GPU 하드웨어 가속(Vulkan)·Impeller 충돌 | 위의 swiftshader + `--no-enable-impeller` |
| Gradle `Connection refused`, SDK/NDK 다운로드 실패 | `~/.gradle/gradle.properties`의 빈 프록시 설정 | 해당 파일의 `systemProp.*.proxy*` 줄 주석 처리 |
| `NDK not configured` | NDK 미설치 | 프록시 해결 후 재빌드하면 자동 설치됨 |
| 이미지가 전부 베이지 박스 | 오프라인 (이미지가 네트워크 로드) | 정상 폴백. 온라인에서 재실행 |
| 마지막 본 화면에서 계속 시작됨 | 앱 프로세스가 살아있음 | `adb shell am force-stop com.example.logzine_app` 후 재실행, 또는 실행 터미널에서 `R` |

## 완전 초기화 실행 (처음 화면부터)

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb shell am force-stop com.example.logzine_app
& $adb shell am start -n com.example.logzine_app/.MainActivity
```

## 에러가 계속되면

에러 메시지 전체를 복사해 AI에게 붙여넣고, 그래도 안 풀리면 팀 채팅에 스크린샷 (혼자 1시간 이상 붙잡지 말 것).
