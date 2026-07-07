# LOGZINE 디자인 정리 (Design Reference)

> 지금 코드 곳곳(`lib/theme.dart`, 각 페이지, `.agents/skills/logzine-ui`)에 흩어져 있는
> 디자인 요소를 **있는 그대로 한곳에 모은** 문서입니다.
> "현황 정리 → 여기서부터 같이 다듬기"가 목적이라, 마지막 §8에 **정돈이 필요한 부분**을 따로 모아뒀어요.
>
> - 현재 단계: UI/UX 데모 (인증·서버 없음)
> - 색의 **원천(source of truth)**: `logzine_app/lib/theme.dart`의 `AppColors`
> - 이 문서와 코드가 어긋나면 **코드가 정답** — 고치면 이 문서도 같이 업데이트

---

## 1. 브랜드 한 줄

> **Curate your quiet taste.**
> 취향 기반 에디토리얼 매거진 — 조용하고 따뜻한, 종이 잡지 같은 읽기 경험.

- 무드: 크림 배경 · 딥그린 포인트 · 세리프 표제 = "조용한 편집숍" 느낌
- 톤: 차분함(calm) · 따뜻함(warm) · 미니멀(minimal) · 에디토리얼(editorial)

---

## 2. 색상 (Color)

### 2-1. 코어 토큰 — `AppColors` (이것만 쓰는 게 원칙)

| 토큰 | HEX | 용도 |
|---|---|---|
| `screen` | `#F7F5F0` | 화면 배경 (크림) |
| `card` | `#FFFFFF` | 카드·입력창 배경 |
| `canvas` | `#E7E4DD` | 바깥 웜 그레이지 (앱 밖 여백) |
| `border` | `#E5E5E0` | 선·테두리·구분선 |
| `placeholder` | `#EDEBE4` | 이미지 로딩 자리 |
| `ink` / `textPrimary` | `#1C1C1E` | 제목·본문·버튼 잉크 |
| `body` / `inkHover` | `#4A5568` | 보조 본문·슬레이트 |
| `textSecondary` | `#8A8A8E` | 보조 텍스트 |
| `textMuted` | `#B0B0B4` | 가장 흐린 텍스트·카운터 |
| `forest` | `#1C4A36` | **주 버튼·선택 칩·활성 상태** (딥 그린) |
| `forestDark` | `#153A2A` | 딥그린 pressed |
| `wine` | `#8E3B46` | 로고 밑줄·포인트 |

> 별칭: `primary=ink`, `primaryDark=inkHover`, `background=screen`, `surface=card` (구 회원가입 페이지 호환용)

### 2-2. 서브 크림 — `#F3EFE6` ⚠️ 토큰 아님

카드 안의 은은한 베이지 배경. **5곳에서 하드코딩으로 반복**됨 (온보딩 카드, 취향 태그 pill, 추천 태그 박스 등).
→ 사실상 토큰인데 `AppColors`에 없음. **§8 정돈 대상 1번.**

### 2-3. 기능별 팔레트 (특정 화면 전용, 의도된 하드코딩)

**리더 하이라이트** (`reader_page.dart`) — 펜 색 / 본문에 칠해지는 옅은 배경:

| 펜(스와치) | HEX | 칠해진 배경 | HEX |
|---|---|---|---|
| 노랑 | `#E9C46A` | → | `#F2DE9E` |
| 초록 | `#A3C9A8` | → | `#C9E0C6` |
| 핑크 | `#C98B9B` | → | `#EBC5CF` |
| 밑줄 펜 | `#3A3A3C` | (배경 대신 밑줄) | — |
| 추가 스와치 | `#9DB8D2` 블루 · `#E0A458` 앰버 · `#B39BC8` 퍼플 | | |

**나무 선반 그라데이션** (디스커버·라이브러리 매거진 선반):
`#DCC5A2 → #B8986C` (LinearGradient) — 두 화면에 중복 정의됨. **§8 정돈 대상 3번.**

**앰버 포인트** `#E0A83C` — "Today's keyword" ☀ 별 아이콘. 리더·공용위젯 2곳 중복.

### 2-4. 소셜 로그인 브랜드색 (`login_email_page.dart`, 외부 규정색이라 예외)

- 카카오 `#FEE500` · 구글 G 로고 `#4285F4` `#EA4335` `#FBBC05` `#34A853` · 애플 아이콘

---

## 3. 타이포그래피 (Type)

폰트는 `google_fonts`로 런타임 로드 (최초 실행 시 네트워크 필요). **새 폰트 추가 금지.**

| 역할 | 폰트 | 헬퍼 | 예시 |
|---|---|---|---|
| 영문 로고·대표제 | **Cormorant Garamond** (세리프) | `logoStyle()` | `LOGZINE`, `Today's stand` |
| 한글 제목 | **Noto Serif KR** (세리프) | `serifHeading()` | 화면 한글 제목 |
| 본문·UI 기본 | **Noto Sans KR** (산세리프) | 테마 기본 | 버튼·본문·라벨 |

**헬퍼 기본값**
- `logoStyle({size:26, weight:w600, letterSpacingEm:0.14, color:textPrimary})`
- `serifHeading({size:19, weight:w600, letterSpacing:-0.3, color:textPrimary})`

**실사용 크기 관례**
- 화면 대제목(영문): `logoStyle(size: 28~32)`
- 섹션 라벨: 15 / w600 / ink (또는 14.5 / w600)
- 본문: 13.5~14 / body
- 보조·카운터: 12~13 / textMuted

---

## 4. 여백 · 레이아웃 (Spacing)

- **화면 좌우 패딩: 24** (고정)
- 섹션 간격: 22~26
- 카드 내부 패딩: 14~16
- 요소 사이 작은 간격: 8 / 10 / 12
- 배경은 항상 `AppColors.screen`, `crossAxisAlignment.stretch` 기본

---

## 5. 컴포넌트 (Components)

수치까지 맞추는 게 "완성도"의 핵심.

| 컴포넌트 | 스펙 |
|---|---|
| **카드** | 흰 배경 + `border` 1px + radius **12~16** |
| **주 버튼** | `forest` 채움 · 흰 글자 · 높이 **52~54** · radius **10** · 15 / w600 |
| **보조 버튼** | 흰 배경 + `border` 아웃라인 · 주 버튼과 같은 크기 |
| **칩(선택형)** | 선택 시 `forest` 채움/흰 글자, 미선택 시 흰 배경+아웃라인 (항상 토글) |
| **태그 pill(표시용)** | `#F3EFE6` 배경 · radius 20 · 13 / w500 (읽기 전용, 토글 아님) |
| **입력창** | 흰 배경 · border 1px · radius 8 · focus 시 ink 1.4px |

### 공용 위젯 (새로 만들기 전 반드시 재사용)

| 위젯 | 파일 | 용도 |
|---|---|---|
| `LogzineTopBar` | `common_widgets.dart` | 상단 바 (뒤로가기/벨/설정) |
| `SectionHeader` | `common_widgets.dart` | 섹션 제목 + View all |
| `KeywordChip` | `common_widgets.dart` | ☀ Today's keyword 칩 |
| `TasteChip` | `onboarding_widgets.dart` | 선택형 태그 칩 |
| `NetworkPhoto` | `onboarding_widgets.dart` | 이미지 로더 (실패 폴백 내장, 이미지엔 이것만) |
| `OnboardingPrimaryButton` | `onboarding_widgets.dart` | 딥그린 주 버튼 |
| `LogzineBottomNav` | `logzine_bottom_nav.dart` | 하단 5탭 |

---

## 6. 아이콘 · 모션

- 아이콘: Material Icons (`Icons.*`). AI 연출엔 `Icons.auto_awesome`(✨), 완료엔 `Icons.check_circle`
- 모션(현재 구현):
  - 온보딩② 분석 진행 바 — 4구간 순차 채움 (2.6s)
  - 디스커버 선반 — PageView 스케일 애니메이션
  - 리더 진행률 — 스크롤 ↔ 슬라이더 양방향

---

## 7. 화면 계층 규칙

- 하단 5탭(홈/디스커버/서재/저장/My)은 `MainShell` 안에서만 (탭 화면에 `bottomNavigationBar` 직접 X)
- 상세·리더는 셸 위에 push되는 전체 화면 (하단 탭 없음, ← 뒤로)
- 온보딩/로그인 완료 → `pushNamedAndRemoveUntil('/main', ...)`로 스택 초기화

---

## 8. 정돈이 필요한 부분 (여기서부터 같이 수정) 🔧

> 지금 "흩어져 있음"의 실체. 우선순위와 함께 정리했어요. 하나씩 결정하며 다듬어 가요.

| # | 항목 | 현재 상태 | 다듬을 방향 | 영향 |
|---|---|---|---|---|
| 1 | **서브 크림 `#F3EFE6`** | 5곳 하드코딩 | `AppColors.cream`(가칭) 토큰으로 승격 | 일관성·유지보수 |
| 2 | **버튼 기준 2종 혼재** | `theme.dart`의 전역 버튼 테마(ink 채움·높이48·radius6·13px)가 실제 신규 화면 버튼(forest·54·radius10·15px)과 **다름** | 전역 버튼 테마를 신규 기준으로 통일하거나, 레거시용임을 명시 | 일관성(중요) |
| 3 | **나무 선반 그라데이션** | 디스커버·라이브러리에 `#DCC5A2→#B8986C` 중복 | 공용 상수/토큰으로 1곳에 | 중복 제거 |
| 4 | **앰버 `#E0A83C`** | 리더·공용위젯 2곳 중복 | 토큰화 | 중복 제거 |
| 5 | **온보딩 언어 혼용** | 영문 UI에 한글이 한 문장 안에 섞임 (`Analysis complete — 태그를 확인해보세요`) 등 | 온보딩 카피를 한 언어로 통일 (브랜드상 **영어 통일** 제안) | 완성도(눈에 띔) |
| 6 | **취향 프로필 AI 요약 위계** | 클라이맥스 문장이 13.5px로 얌전함 | 세리프 인용구로 키워 "와" 포인트화 | 완성도(하이라이트) |
| 7 | **원오프 웜그레이** | 점선보더 `#CDBFA9`·진행바 트랙 `#E8E5DE` 등 | 필요 시 border 계열로 정리 | 낮음 |

---

### 다음 스텝
이 표(§8)에서 **어떤 번호부터** 손볼지 정하면, 코드로 반영하고 핫 리로드로 바로 보여드립니다.
값을 바꾸면 이 문서의 해당 항목도 함께 업데이트해 항상 코드와 일치시킵니다.
