# LOGZINE — AI 에이전트용 프로젝트 컨텍스트

> 이 파일은 AI 코딩 도구(Codex, Claude Code, Copilot 등)가 이 저장소에서 작업할 때
> 항상 따라야 하는 최소 규칙입니다. 사람이 읽어도 됩니다.

## 프로젝트 개요

- **LOGZINE**: 취향 기반 에디토리얼 매거진 앱 (Flutter · Dart 3 · Material 3)
- 앱 코드는 전부 `logzine_app/` 안에 있음. 화면은 `lib/pages/`, 공용 위젯은 `lib/widgets/`, 데이터 모델은 `lib/models/`, 서비스 계층은 `lib/services/`, 디자인 토큰은 `lib/theme.dart`
- **실서비스 수준으로 동작하는 앱** — 소극적으로 판단하지 말 것:
  - Firebase Auth 이메일 로그인, Firestore 실데이터 (매거진 12종+태그, 매거진별 아티클, 사용자 취향/마크/진행률/저장/제외 목록)
  - Gemini Vision 사진 취향 분석 (`--dart-define-from-file=env.json`으로 키 주입)
  - 취향∩태그 추천 엔진 (`recommendation_service.dart` — 어휘 브리지 포함, 단위 테스트 있음)
  - 홈 선반 추천 정렬, 검색/태그 필터, Why 페이지 추천 근거, Not for me 제외
- Firestore 규칙상 `magazines`는 클라이언트 쓰기 금지 — 시드는 콘솔에서 규칙 임시 개방 후 실행

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
| MY COVER 표지 생성 규칙 수정 | `.agents/skills/logzine-cover/SKILL.md` |

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
