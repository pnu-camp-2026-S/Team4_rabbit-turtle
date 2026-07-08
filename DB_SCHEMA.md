# LOGZINE Firestore 스키마 v3

> Firestore는 스키마리스이므로 이 문서가 팀의 스키마 계약이다.
> 컬렉션/필드를 추가·변경할 때는 이 문서를 먼저 수정하는 PR을 올린다.

## 전체 구조
magazines/{magazineId}               매거진 (공개 읽기)
└ articles/{articleId}             아티클 본문
publishers/{publisherId}             발행사 (공개 읽기)
users/{uid}                          사용자 (본인만 읽기/쓰기)
├ marks/{markId}                   하이라이트·밑줄·메모
├ progress/{articleId}             읽기 진행률
├ saved/{articleId}                저장한 아티클
├ subscriptions/{magazineId}       구독한 매거진
└ follows/{publisherId}            팔로우한 발행사

## magazines/{magazineId}

문서 ID: 자동 생성

| 필드 | 타입 | 설명 |
|---|---|---|
| title | string | 매거진 이름 (예: "CEREAL") |
| tagline | string | 한 줄 소개 |
| issue | string | 호수 표기 (예: "Vol. 34") |
| coverUrl | string | 커버 이미지 URL |
| tags | array<string> | 취향 태그 (추천 매칭용) — **어휘는 `kMoodVocab`(lib/models/mood_analysis.dart)과 동일 집합만 사용**. 사용자 tasteTags와 같은 단어여야 매칭이 성립한다. 현재 시드는 빈 배열 (태그 시드는 추천 기능 작업에서) |
| order | number | 선반 정렬 순서 |
| createdAt | timestamp | 생성 시각 |

> 클라이언트 모델: `lib/models/magazine.dart`

## magazines/{magazineId}/articles/{articleId}

문서 ID: 자동 생성

| 필드 | 타입 | 설명 |
|---|---|---|
| title | string | 아티클 제목 |
| order | number | 매거진 내 순서 |
| pageCount | number | 리더 페이지 수 표기용 |
| paragraphs | array<map> | 본문. 각 원소는 { segments: array<string> } |

> paragraphs를 segment 배열로 저장하는 이유: 리더(reader_page.dart)가
> 문장 조각(segment) 단위로 탭을 인식하므로, 저장 구조를 동일하게 맞춰야
> 하이라이트 좌표 (paragraphIdx, segmentIdx)가 그대로 성립한다.

## users/{uid}

문서 ID: Firebase Auth uid. 로그인/가입 성공 시 `UserService.ensureUserDoc()`이 생성 (멱등).

| 필드 | 타입 | 설명 |
|---|---|---|
| email | string | 가입 이메일 |
| tasteTags | array<string> | 온보딩에서 선택한 취향 태그 (저장 시 전체 교체) |
| createdAt | timestamp | 가입 시각 |

## users/{uid}/marks/{markId}

문서 ID: `{articleId}_{paragraphIdx}_{segmentIdx}` — 같은 문장에
마크 중복 생성을 문서 ID 차원에서 차단.

| 필드 | 타입 | 설명 |
|---|---|---|
| articleId | string | 대상 아티클 |
| magazineId | string | 대상 매거진 (역참조용) |
| paragraphIdx | number | 문단 인덱스 |
| segmentIdx | number | 조각 인덱스 |
| type | string | "highlight" \| "underline" \| "memo" |
| color | string | 하이라이트 색 hex (memo는 null 허용) |
| memoText | string | 메모 내용 (memo 타입만) |
| createdAt | timestamp | 생성 시각 |

## users/{uid}/progress/{articleId}

| 필드 | 타입 | 설명 |
|---|---|---|
| magazineId | string | 역참조용 |
| percent | number | 0~100 |
| lastPage | number | 마지막 페이지 |
| updatedAt | timestamp | 갱신 시각 |

## users/{uid}/saved/{articleId}

Saved 탭이 추가 조회 없이 목록을 그릴 수 있도록 표시용 필드를 **비정규화**(원본 복사)해서 저장한다.
원본(매거진/아티클 제목·커버)이 바뀌어도 저장 시점의 값이 유지되는 한계는 v2에서 수용.

| 필드 | 타입 | 설명 |
|---|---|---|
| magazineId | string | 역참조용 |
| articleTitle | string | 표시용 (저장 시점 아티클 제목, 비정규화) |
| magazineTitle | string | 표시용 (저장 시점 매거진 이름, 비정규화) |
| coverUrl | string | 표시용 썸네일 (비정규화) |
| savedAt | timestamp | 저장 시각 |

## users/{uid}/subscriptions/{magazineId}

매거진 구독. 문서 ID = magazineId (중복 구독 방지, saved와 동일 패턴)

| 필드 | 타입 | 설명 |
|---|---|---|
| magazineTitle | string | 표시용 (구독 시점 매거진 이름, 비정규화) |
| coverUrl | string | 표시용 썸네일 (비정규화) |
| subscribedAt | timestamp | 구독 시각 |

## publishers/{publisherId}

문서 ID: 자동 생성. 발행사 (공개 읽기, magazines와 동일 권한)

| 필드 | 타입 | 설명 |
|---|---|---|
| name | string | 발행사명 |
| logoUrl | string | 로고 이미지 URL |
| tagline | string | 한 줄 소개 |
| order | number | 목록 정렬 순서 |
| createdAt | timestamp | 생성 시각 |

## users/{uid}/follows/{publisherId}

발행사 팔로우. 문서 ID = publisherId (중복 팔로우 방지). saved와 동일하게
표시용 필드를 비정규화(원본 복사)해서 저장 — 팔로우 목록을 추가 조회 없이 그린다.

| 필드 | 타입 | 설명 |
|---|---|---|
| publisherName | string | 표시용 (비정규화) |
| logoUrl | string | 표시용 아바타 이미지 (팔로우 시점 발행사 로고, 비정규화) |
| followedAt | timestamp | 팔로우 시각 |

## Security Rules

- magazines/** : 누구나 읽기 (비로그인 브라우징 지원), 쓰기는 금지 (시드는 관리자가 규칙 임시 개방 후 수행)
- publishers/** : 누구나 읽기, 쓰기는 금지 (magazines와 동일 — 시드는 관리자가 규칙 임시 개방 후 수행)
- users/{uid}/** : request.auth.uid == uid 인 경우에만 읽기/쓰기 (marks/progress/saved/subscriptions/follows 전부 포함)
- 그 외 전부 거부 (기본 deny)

규칙 전문: `logzine_app/firestore.rules` — 수정 시 PR 리뷰 후
`firebase deploy --only firestore:rules`로 배포한다. 콘솔에서 직접 수정하지 않는다.

## 연동 현황

| 컬렉션 | 서비스 | 상태 |
|---|---|---|
| magazines | MagazineService | ✅ 연동 (디스커버 선반) |
| articles | MagazineService (시드/ID 조회) | 🔶 시드 1편 — 리더 본문 동적화는 예정 |
| users | UserService | ✅ 연동 (문서 생성 + tasteTags) |
| marks / progress | MarkService | ✅ 연동 (리더) |
| saved | SavedService | ✅ 저장/해제 연동 |
| subscriptions | SubscriptionService | ✅ 연동 |
| publishers / follows | PublisherService | ✅ 연동 (library 발행사 팔로우) |

## 다음 로드맵

1. 매거진 태그 시드 (kMoodVocab 어휘) → 취향 매칭 추천 (`where tags arrayContainsAny tasteTags`)
2. 리더 본문 동적화 (articles.paragraphs 렌더링)
3. publishers 시드 데이터 입력 (현재 컬렉션 정의만 있고 실 데이터 없음 — library 발행사 탭이 데모로 남아있는 이유)