# Team4_rabbit-turtle
We are going to get 1st prize🏆

---

# LOGZINE

> **Curate your quiet taste.**
> 취향 기반 에디토리얼 매거진 앱 — 사진으로 무드를 분석하고, 취향에 맞는 매거진을 추천받아, 밑줄 긋고 메모하며 읽는 조용한 읽기 경험.

Flutter로 구현한 데모 앱입니다. 로그인 → 온보딩(취향 분석) → 홈/디스커버 → 읽기(하이라이트) → 서재/아카이브까지 **전체 유저 플로우가 화면 단위로 연결**되어 있으며, 백엔드 없이 UI/UX와 인터랙션을 검증하는 단계입니다.

---

## 1. 화면 플로우 (User Journey)

```
로그인 웰컴 ─ Start with Email ─→ 이메일 로그인 ─ Continue / 소셜 ─→ 온보딩
    │                                                                │
    └─ Browse without login ──→ 디스커버                              ▼
                                             ① Upload your mood (사진 업로드)
                                             ② Choose while we read (태그 선택)
                                             ③ Your taste profile (취향 프로필)
                                                        │ Start recommendations
                                                        ▼
        ┌─────────────────── 하단 5탭 내비게이션 ───────────────────┐
        │  Home     Discover     Library     Saved      My         │
        │  홈 피드    Today's stand  My Library  (준비 중)   Archive   │
        └───────────────────────────────────────────────────────┘
                        │ 매거진 카드 탭
                        ▼
              Why this issue (추천 이유) ─ Start reading ─→ Reader (읽기 화면)
                                                            · 진행률 슬라이더
                                                            · 하이라이트 / 메모
```

## 2. 라우트 맵

| 라우트 | 파일 | 화면 | 상태 |
|---|---|---|---|
| `/` | `login_welcome_page.dart` | 웰컴 (히어로 + 로그인 진입) | ✅ 완성 |
| `/login/email` | `login_email_page.dart` | 이메일/카카오/Apple/Google 로그인 | ✅ UI 완성 (인증 미연동) |
| `/onboarding/upload` | `mood_upload_page.dart` | 온보딩① 무드 사진 업로드 | ✅ 완성 (갤러리 연동 전) |
| `/onboarding/tags` | `mood_tags_page.dart` | 온보딩② 분석 중 태그 선택 | ✅ 완성 |
| `/onboarding/profile` | `taste_profile_page.dart` | 온보딩③ 취향 프로필 | ✅ 완성 |
| `/home` | `home_page.dart` | 홈 피드 (이어 읽기·오늘의 픽·하이라이트) | ✅ 완성 |
| `/discover` | `discover_page.dart` | Today's stand (매거진 선반 캐러셀) | ✅ 완성 |
| `/discover/why` | `why_issue_page.dart` | Why this issue (추천 이유) | ✅ 완성 |
| `/reader` | `reader_page.dart` | 읽기 화면 (진행률·하이라이트·메모) | ✅ 완성 |
| `/library` | `library_page.dart` | My Library (프로필·통계·발행사·선반) | ✅ 완성 |
| `/archive` | `archive_page.dart` | Archive (저장 글·최근 본·설정) | ✅ 완성 |
| `/signup`, `/interest`, `/explore`, `/create`, `/mypage` | 기존 페이지들 | 초기 프로토타입 (신규 플로우에서 미사용) | 🗄 레거시 |

> **레거시 페이지 정리 시 주의**: `/explore` 등은 현재 내비게이션에서 빠져 있지만 라우트는 살아 있음. 삭제하려면 `main.dart` 라우트와 import를 함께 제거할 것.

## 3. 프로젝트 구조

```
lib/
├─ main.dart                  # 라우트 등록 (신규 화면 추가 시 여기에)
├─ theme.dart                 # 디자인 토큰: AppColors, logoStyle(), buildAppTheme()
├─ pages/
│  ├─ login_welcome_page.dart
│  ├─ login_email_page.dart   # 구글 G 로고 CustomPainter 포함
│  ├─ mood_upload_page.dart   # 점선 보더 CustomPainter 포함
│  ├─ mood_tags_page.dart     # 진행 바 애니메이션 포함
│  ├─ taste_profile_page.dart
│  ├─ home_page.dart          # 시간대별 인사말 로직 포함
│  ├─ discover_page.dart      # Magazine 모델 + kMagazines 데이터 + MagazineCover 위젯
│  ├─ why_issue_page.dart
│  ├─ reader_page.dart        # 하이라이트/메모/진행률 (가장 복잡한 화면)
│  ├─ library_page.dart       # ReadProgressBar 공용 위젯 포함
│  ├─ archive_page.dart
│  └─ (signup/interest/explore/create/mypage — 레거시)
└─ widgets/
   ├─ logzine_logo.dart       # 세리프 워드마크 + 와인색 밑줄
   ├─ logzine_bottom_nav.dart # 하단 5탭 (탭 → pushReplacementNamed)
   └─ onboarding_widgets.dart # OnboardingTopBar/Header, NetworkPhoto, TasteChip, 그린 버튼
```

**공용 컴포넌트 위치 규칙**
- 2개 이상 화면에서 쓰는 위젯 → `widgets/` 로 승격
- 화면 전용 위젯 → 해당 페이지 파일 안에 `_PrivateWidget` 으로 유지
- 데이터 모델이 화면에 붙어 있는 경우(`Magazine` in `discover_page.dart`) → 백엔드 붙일 때 `models/` 디렉터리로 분리 권장

## 4. 디자인 시스템

### 색상 (`theme.dart` — `AppColors`)

| 토큰 | 값 | 용도 |
|---|---|---|
| `screen` | `#F7F5F0` | 화면 배경 (크림) |
| `forest` | `#1C4A36` | 주 버튼·선택 칩·활성 탭 (딥 그린) |
| `wine` | `#8E3B46` | 로고 밑줄 포인트 |
| `ink` | `#1C1C1E` | 제목·본문 텍스트 |
| `border` | `#E5E5E0` | 카드 테두리·구분선 |
| `textSecondary` / `textMuted` | `#8A8A8E` / `#B0B0B4` | 보조 텍스트 |
| 하이라이트 팔레트 | `#E9C46A` 노랑 · `#A3C9A8` 초록 · `#C98B9B` 핑크 · `#3A3A3C` 밑줄펜 | 리더 하이라이트 (`reader_page.dart`) |
| 나무 선반 | `#DCC5A2 → #B8986C` 그라데이션 | 디스커버·라이브러리 선반 |

### 타이포그래피
- **영문 로고/대제목**: Cormorant Garamond (`logoStyle()` 헬퍼) — `LOGZINE`, `Today's stand`, `Quiet Materials` 등 세리프 감성의 핵심
- **한글 제목**: Noto Serif KR (`serifHeading()`)
- **본문**: Noto Sans KR (테마 기본)
- 폰트는 `google_fonts` 패키지로 런타임 로드 → **최초 실행 시 네트워크 필요**

### 컴포넌트 관례
- 카드: 흰 배경 + `AppColors.border` 1px + radius 12~16
- 주 버튼: `forest` 채움, 흰 글자, 높이 52~54, radius 10
- 보조 버튼: 흰 배경 아웃라인, 같은 크기
- 칩(`TasteChip`): 선택 시 `forest` 채움/흰 글자, 미선택 시 흰 배경 아웃라인 — 항상 탭 토글 가능하게
- 화면 좌우 패딩 24, 섹션 간격 22~26

## 5. 구현된 기능 상세

### 리더 (reader_page.dart) — 데모의 핵심
- **읽기 진행률**: 스크롤 위치 ↔ 진행률 슬라이더 양방향 연동. 슬라이더 썸이 북마크 리본 모양(`_BookmarkThumbShape` CustomPainter). `4 / 12` 페이지 + `34%` 표시
- **하이라이트(Pen)**: 하이라이트 모드에서 본문 문장을 탭 → 선택한 색으로 배경 표시. 같은 색으로 다시 탭하면 제거. 검정 스와치는 배경 대신 **밑줄**로 적용
- **메모(Memo)**: 문장 탭 → 다이얼로그로 메모 입력 → Marked passages 목록에 📝로 표시
- **Undo**: 마크 변경 이력 스택으로 되돌리기 (이력 없으면 비활성)
- **팔레트 +**: 바텀시트에서 추가 색상 선택 → 팔레트에 동적 추가
- **Marked passages**: 검색 필터, 문단별 페이지 라벨(p.4~), 상위 2개 + `View all marks` 바텀시트
- 본문 문장은 `_paragraphs` 상수의 **조각(segment) 단위**로 탭 인식 (`TapGestureRecognizer`, initState에서 생성/dispose 관리)

### 온보딩
- 사진 썸네일 X 삭제/재추가 (데모: 갤러리 대신 프리셋 4장 순환)
- 태그 선택 상태 관리(`Set<String>`), AI 추천 태그도 동일 칩으로 토글
- 코멘트 입력 120자 실시간 카운터

### 디스커버/홈/서재
- 매거진 선반: `PageView(viewportFraction 0.52)` + 스케일 애니메이션, 옆 카드 탭 시 중앙으로 스냅, 중앙 카드 탭 시 상세 이동
- 홈: `DateTime.now().hour` 기반 인사말, 이어 읽기(진행률 재사용), 최근 하이라이트 인용 카드
- 진행 바(`ReadProgressBar`)는 라이브러리/아카이브/홈에서 공용

### 이미지 처리
- 사진 에셋이 없어 **Unsplash URL을 직접 로드** (`NetworkPhoto`) — 로딩/실패 시 웜 베이지 플레이스홀더로 폴백
- 오프라인이면 모든 이미지가 플레이스홀더로 보이는 것이 정상

## 6. 실행 방법

```powershell
cd logzine_app
flutter pub get

# ⚠️ 이 PC에서는 에뮬레이터를 반드시 소프트웨어 GPU로 실행할 것 (아래 트러블슈팅 참고)
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone -gpu swiftshader_indirect

# 부팅 완료 후
flutter run --no-enable-impeller
```

- 빠른 UI 확인만 필요하면: `flutter run -d chrome` → F12 → `Ctrl+Shift+M` → iPhone 프리셋
- 핫 리로드: 실행 터미널에서 `r`, 재시작 `R`, 종료 `q`

### 트러블슈팅 (이 프로젝트에서 실제 겪은 이슈)

| 증상 | 원인 | 해결 |
|---|---|---|
| 앱 렌더링 시작 순간 에뮬레이터가 통째로 종료 | GPU 하드웨어 가속(Vulkan)과 Impeller 충돌 | 에뮬레이터 `-gpu swiftshader_indirect` + `flutter run --no-enable-impeller`. **`flutter emulators --launch`(기본 GPU) 사용 금지** |
| Gradle 빌드가 `Connection refused`로 실패, NDK/SDK 다운로드 불가 | `C:\Users\<user>\.gradle\gradle.properties`에 호스트가 빈 프록시 설정 | 해당 `systemProp.*.proxy*` 줄 주석 처리 (2026-07-03 조치 완료) |
| `NDK not configured` | NDK 미설치 | 프록시 해결 후 재빌드하면 Gradle이 자동 설치 (NDK 28.2 / SDK 36 / CMake 3.22 설치 완료됨) |
| 이미지가 전부 베이지 박스로 보임 | 네트워크 차단/오프라인 | 정상 폴백 동작. 온라인에서 재실행 |

## 7. 다음 구현 로드맵

### 우선순위 높음
1. **상태 관리 도입** — 현재 모든 상태가 화면 로컬(`setState`). 취향 태그·저장·읽기 진행률·하이라이트가 화면 간 공유되지 않음 → Riverpod(권장) 또는 Provider로 전역화
2. **데이터 모델 분리** — `Magazine`, `Article`, `Mark`, `TasteProfile`을 `lib/models/`로 추출하고 화면은 모델만 소비하도록
3. **실제 인증** — 이메일/카카오/Apple/Google 버튼이 전부 `/onboarding/upload`로 넘어가는 상태. Firebase Auth 또는 자체 백엔드 연동. `login_email_page.dart`의 `onPressed`만 교체하면 됨
4. **리더 콘텐츠 동적화** — 본문이 `_paragraphs` 상수 하드코딩. 아티클 데이터(문단/이미지/페이지 수)를 모델로 받아 렌더링하도록 일반화. 하이라이트는 (articleId, paragraphIdx, segmentIdx) 키로 로컬 저장(`shared_preferences` → 이후 서버 동기화)

### 우선순위 중간
5. **이미지 에셋 교체** — Unsplash URL을 실제 브랜드 에셋으로. `assets/images/` + `pubspec.yaml` 등록 후 `NetworkPhoto` → `Image.asset` 스위치 가능한 래퍼로
6. **온보딩 사진 업로드 실제 구현** — `image_picker` 패키지로 갤러리/카메라 연동 (`mood_upload_page.dart`의 `_addPhoto()` 교체)
7. **Saved 탭 구현** — 하단 내비 index 3이 스낵바 처리 중. 리더의 Save 상태와 연동된 저장 목록 화면
8. **View all / 검색 등 데모 스텁 채우기** — 각 화면의 `onTap: () {}` 및 스낵바 자리 (`grep 'View all'`, `grep '준비 중'`으로 위치 확인 가능)

### 우선순위 낮음
9. 다크 모드 (토큰이 `AppColors`에 모여 있어 확장 용이)
10. 애니메이션 다듬기 (화면 전환 Hero, 선반 물리 스크롤)
11. 레거시 페이지(`explore/create/mypage/signup/interest`) 정리 또는 신규 디자인으로 이관
12. 테스트 — 현재 `test/`는 템플릿 상태. 최소한 라우트 스모크 테스트와 리더 마크 로직 단위 테스트부터

## 8. 새 화면 추가 체크리스트

1. `lib/pages/xxx_page.dart` 생성 — 배경 `AppColors.screen`, 좌우 패딩 24
2. 제목은 `logoStyle()`, 섹션 라벨은 15/w600 관례 따르기
3. 공용 위젯(`OnboardingTopBar`, `TasteChip`, `NetworkPhoto`, `LogzineBottomNav`) 재사용
4. `main.dart`에 import + 라우트 등록
5. 탭 화면이면 `LogzineBottomNav(currentIndex: n)` + `logzine_bottom_nav.dart`의 `_onTap` 분기 추가
6. `flutter analyze` 통과 확인 후 에뮬레이터에서 실제 렌더링 확인 (위 실행 방법 참고)

---

**기술 스택**: Flutter (Dart SDK ^3.12) · Material 3 · google_fonts ^8.1
**타깃**: Android (검증 완료) / iOS·Web (미검증)
