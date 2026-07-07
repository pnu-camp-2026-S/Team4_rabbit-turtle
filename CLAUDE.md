# LOGZINE — AI 에이전트용 프로젝트 컨텍스트

> 이 파일은 AI 코딩 도구(Codex, Claude Code, Copilot 등)가 이 저장소에서 작업할 때
> 항상 따라야 하는 최소 규칙입니다. 사람이 읽어도 됩니다.

## 프로젝트 개요

- **LOGZINE**: 취향 기반 에디토리얼 매거진 앱 (Flutter · Dart 3 · Material 3)
- 앱 코드는 전부 `logzine_app/` 안에 있음. 화면은 `lib/pages/`, 공용 위젯은 `lib/widgets/`, 데이터 모델은 `lib/models/`, 디자인 토큰은 `lib/theme.dart`
- 현재 UI/UX 데모 단계 — 인증·서버 없음, 콘텐츠는 데모 데이터

## 절대 규칙 (위반 금지)

1. **main 브랜치에 직접 커밋/푸시하지 않는다.** 반드시 브랜치 → PR
2. **색상을 하드코딩하지 않는다.** `lib/theme.dart`의 `AppColors` 토큰만 사용
3. **완료 전 `flutter analyze`와 `flutter test`가 통과해야 한다** (logzine_app 폴더에서 실행)
4. API 키·토큰·시크릿을 커밋하지 않는다

## 작업 유형별 상세 매뉴얼 (해당 작업 시 반드시 읽고 따를 것)

| 작업 | 읽을 파일 |
|---|---|
| 화면/위젯 만들기·수정 (UI 작업 전부) | `.agents/skills/logzine-ui/SKILL.md` |
| 브랜치·커밋·PR (git 작업 전부) | `.agents/skills/logzine-workflow/SKILL.md` |
| 앱 실행·에뮬레이터 문제 | `.agents/skills/logzine-run/SKILL.md` |

## 빠른 실행

```bash
cd logzine_app
flutter pub get
flutter run -d chrome        # 웹으로 빠른 확인 (F12 → Ctrl+Shift+M → 폰 비율)
```

⚠️ 안드로이드 에뮬레이터가 켜자마자 죽으면 → `logzine-run` 스킬 참고 (GPU 소프트웨어 렌더링 필수)

## 문서 지도

- 서비스 소개·화면 플로우·로드맵: `README.md`
- 협업 규칙 전문: `CONTRIBUTING.md`
- 작업 목록: GitHub Issues (P1/P2/P3 라벨)
- 화면·기능 상세: GitHub Wiki
