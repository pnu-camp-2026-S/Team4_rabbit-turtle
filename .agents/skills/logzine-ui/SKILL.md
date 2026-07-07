---
name: logzine-ui
description: LOGZINE Flutter 앱의 화면·위젯을 만들거나 수정할 때 따르는 디자인 시스템과 UI 규칙. UI 작업이면 반드시 이 문서대로 진행한다.
---

# LOGZINE UI 작업 규칙

## 1. 색상 — `AppColors` 토큰만 사용 (`logzine_app/lib/theme.dart`)

| 토큰 | 값 | 용도 |
|---|---|---|
| `AppColors.screen` | #F7F5F0 | 화면 배경 (크림) |
| `AppColors.forest` | #1C4A36 | 주 버튼·선택 칩·활성 상태 (딥 그린) |
| `AppColors.wine` | #8E3B46 | 로고 밑줄·포인트 |
| `AppColors.ink` | #1C1C1E | 제목·본문 |
| `AppColors.body` | #4A5568 | 보조 본문 |
| `AppColors.border` | #E5E5E0 | 카드 테두리·구분선 |
| `AppColors.textSecondary` / `textMuted` | #8A8A8E / #B0B0B4 | 보조 텍스트 |
| `AppColors.placeholder` | #EDEBE4 | 이미지 로딩 자리 |

- ❌ `Color(0xFF...)` 하드코딩 금지 (하이라이트 팔레트·크림 배경 #F3EFE6 등 기존 관례 색 제외)
- 크림색 서브 배경이 필요하면 `Color(0xFFF3EFE6)` (기존 화면들과 동일 값)

## 2. 타이포그래피

- **영문 대제목·로고**: `logoStyle()` 헬퍼 (Cormorant Garamond 세리프) — 예: `logoStyle(size: 32, weight: FontWeight.w500, letterSpacingEm: 0.0, color: AppColors.ink)`
- **섹션 라벨**: fontSize 15, w600, ink
- **본문**: 테마 기본 (Noto Sans KR) — TextStyle로 크기/색만 조정
- ❌ 새 폰트 패키지 추가 금지

## 3. 컴포넌트 관례 (수치까지 맞출 것)

- **카드**: 흰 배경 + `AppColors.border` 1px + radius 12~16
- **주 버튼**: forest 채움, 흰 글자, 높이 52~54, radius 10, fontSize 15 w600
- **보조 버튼**: 흰 배경 + border 아웃라인, 주 버튼과 같은 크기
- **칩**: 선택 시 forest 채움/흰 글자, 미선택 시 흰 배경+아웃라인 — 항상 탭 토글 가능하게
- **레이아웃**: 화면 좌우 패딩 24, 섹션 간격 22~26

## 4. 공용 위젯 — 새로 만들기 전에 반드시 재사용 (`logzine_app/lib/widgets/`)

| 위젯 | 파일 | 용도 |
|---|---|---|
| `LogzineTopBar` | common_widgets.dart | 상단 바 (뒤로가기/벨/설정 옵션) |
| `SectionHeader` | common_widgets.dart | 섹션 제목 + View all |
| `KeywordChip` | common_widgets.dart | ☀ Today's keyword 칩 |
| `TasteChip` | onboarding_widgets.dart | 선택형 태그 칩 |
| `NetworkPhoto` | onboarding_widgets.dart | 이미지 로더 (로딩/실패 플레이스홀더 내장) |
| `OnboardingPrimaryButton` | onboarding_widgets.dart | 딥그린 주 버튼 |
| `LogzineBottomNav` | logzine_bottom_nav.dart | 하단 5탭 |

- 이미지는 반드시 `NetworkPhoto` 사용 (Image.network 직접 사용 금지 — 실패 폴백이 없음)
- 2개 이상 화면에서 쓸 위젯 → `widgets/`로. 화면 전용 → 페이지 파일 안 `_Private` 클래스로

## 5. 새 화면 추가 체크리스트

1. `lib/pages/xxx_page.dart` 생성 — 배경 `AppColors.screen`, 좌우 패딩 24
2. 상단은 `LogzineTopBar` (상세 화면은 `showBack: true`, 하단 탭 없음)
3. `lib/main.dart`에 import + 라우트 등록
4. 메인 탭 화면이면 `lib/pages/main_shell.dart`의 IndexedStack에 추가
5. `flutter analyze` / `flutter test` 통과 확인

## 6. 화면 계층 규칙

- 하단 5탭(홈/디스커버/서재/저장/My)은 `MainShell` 안에서만 — 탭 화면에 `bottomNavigationBar` 직접 달지 않기
- 상세·리더 등은 셸 위에 push되는 전체 화면 (하단 탭 없음, ← 뒤로가기)
- 온보딩/로그인 완료 시 `pushNamedAndRemoveUntil('/main', ...)`으로 스택 초기화
