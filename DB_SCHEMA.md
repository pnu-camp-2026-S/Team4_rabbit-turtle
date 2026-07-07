# LOGZINE Firestore 스키마 v1

> Firestore는 스키마리스이므로 이 문서가 팀의 스키마 계약이다.
> 컬렉션/필드를 추가·변경할 때는 이 문서를 먼저 수정하는 PR을 올린다.
> 관련: 이슈 #8 (데모 카탈로그 → 백엔드 대체)

## 전체 구조

​```
magazines/{magazineId}               매거진 (공개 읽기)
  └ articles/{articleId}             아티클 본문
users/{uid}                          사용자 (본인만 읽기/쓰기)
  ├ marks/{markId}                   하이라이트·밑줄·메모
  ├ progress/{articleId}             읽기 진행률
  └ saved/{articleId}                저장한 아티클
​```

## magazines/{magazineId}

문서 ID: 자동 생성

| 필드 | 타입 | 설명 |
|---|---|---|
| title | string | 매거진 이름 (예: "CEREAL") |
| tagline | string | 한 줄 소개 |
| issue | string | 호수 표기 (예: "Vol. 34") |
| coverUrl | string | 커버 이미지 URL |
| tags | array<string> | 취향 태그 (추천 매칭용, v1에서는 빈 배열 허용) |
| order | number | 선반 정렬 순서 |
| createdAt | timestamp | 생성 시각 |

> 클라이언트 모델: `lib/models/magazine.dart` — title/tagline/issue/coverUrl은
> 모델 필드명과 1:1 일치. tags/order/createdAt은 서버 전용(모델 확장은 연동 PR에서).

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

문서 ID: Firebase Auth uid

| 필드 | 타입 | 설명 |
|---|---|---|
| email | string | 가입 이메일 |
| tasteTags | array<string> | 온보딩에서 선택한 취향 태그 |
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

| 필드 | 타입 | 설명 |
|---|---|---|
| magazineId | string | 역참조용 |
| savedAt | timestamp | 저장 시각 |

## Security Rules 방침 (v1)

- magazines/** : 로그인 사용자 누구나 읽기, 쓰기는 금지 (시드는 관리자가 콘솔/스크립트로)
- users/{uid}/** : request.auth.uid == uid 인 경우에만 읽기/쓰기
- 그 외 전부 거부 (기본 deny)

규칙 전문과 배포는 feat/firestore-user-data PR에서 다룬다.

## 연동 로드맵

1. docs/db-schema — 이 문서 (현재)
2. feat/firestore-magazines — 시드 입력 + 디스커버 화면 연동 (이슈 #8 해결)
3. feat/firestore-user-data — 온보딩 태그·marks·progress 저장 + Rules 배포