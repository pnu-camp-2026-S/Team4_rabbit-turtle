# UI 노출 키워드 Vocabulary

사진 분석, 매거진 분석, 줄글 보정 결과가 앱 화면에 노출될 때 사용할 수 있는 유일한 키워드 목록이다. `main_keywords`와 `more_signals`에는 아래 `UI 키워드`만 들어갈 수 있다.

## 핵심 원칙

- UI에 노출되는 키워드는 이 파일의 `UI 키워드` 중 하나여야 한다.
- 사진이나 매거진에서 더 구체적인 표현이 나와도 가장 가까운 UI 키워드로 매핑한다.
- 이 목록에 없는 표현은 `main_keywords`에도 `more_signals`에도 넣지 않는다.
- `more_signals`는 애매하거나 보조적인 신호를 보여주는 영역이지만, 여기에도 이 목록에 있는 UI 키워드만 넣는다.
- 내부 추천 매칭은 `mapped_concepts`의 taxonomy `concept_id`를 사용한다.

## 전체 구조

| 대분류 | 영문 캡션 | UI 키워드 |
| --- | --- | --- |
| 음식 | FOOD | 카페, 커피, 디저트, 베이커리, 브런치, 전통차, 와인, 로컬 맛집 |
| 패션 | FASHION | 미니멀, 빈티지, 스트릿, 클래식, 디자이너 브랜드, 스포츠웨어, 액세서리, 데일리룩 |
| 공간 | SPACE | 인테리어, 가구, 한옥, 호텔, 전시 공간, 서점, 정원, 복합문화공간 |
| 여행 | TRAVEL | 도시 여행, 해외 도시, 랜드마크, 골목 탐방, 자연, 숙소, 미식 여행, 스포츠 여행 |
| 예술 | ART | 전시, 현대미술, 건축, 공예, 디자인, 일러스트, 사진, 아트페어 |
| 음악 | MUSIC | 인디, 재즈, 라이브 공연, 페스티벌, 플레이리스트, 바이닐, 클래식, 사운드트랙 |
| 스포츠 | SPORTS | 축구, 야구, 러닝, 요가, 클라이밍, 스포츠 관람, 경기장 투어, 스포츠 여행 |
| 라이프스타일 | LIFESTYLE | 독서, 웰니스, 작업 루틴, 홈라이프, 반려생활, 취미 수집, 조용한 휴식, 로컬 탐방 |

## UI 키워드 매핑

### 음식

| UI 키워드 | mapped_concepts |
| --- | --- |
| 카페 | `place.cafe`, `food_drink.coffee` |
| 커피 | `food_drink.coffee` |
| 디저트 | `food_drink.dessert` |
| 베이커리 | `food_drink.dessert` |
| 브런치 | `food_drink.dessert` |
| 전통차 | `food_drink.tea` |
| 와인 | 없음 |
| 로컬 맛집 | `culture.local_culture` |

### 패션

| UI 키워드 | mapped_concepts |
| --- | --- |
| 미니멀 | 없음 |
| 빈티지 | `mood.aesthetic` |
| 스트릿 | 없음 |
| 클래식 | 없음 |
| 디자이너 브랜드 | 없음 |
| 스포츠웨어 | `sports.live_sports` |
| 액세서리 | 없음 |
| 데일리룩 | `context.daily_leisure` |

### 공간

| UI 키워드 | mapped_concepts |
| --- | --- |
| 인테리어 | `culture.architecture_design`, `mood.aesthetic` |
| 가구 | `culture.architecture_design` |
| 한옥 | `place.traditional_space`, `culture.history_tradition` |
| 호텔 | 없음 |
| 전시 공간 | `place.museum_gallery`, `culture.art_exhibition` |
| 서점 | `place.bookstore`, `activity.reading` |
| 정원 | `place.nature_outdoor`, `mood.relaxed` |
| 복합문화공간 | `context.cultural_outing`, `culture.local_culture` |

### 여행

| UI 키워드 | mapped_concepts |
| --- | --- |
| 도시 여행 | `context.travel`, `travel.city_landmark` |
| 해외 도시 | `travel.overseas_city`, `context.travel` |
| 랜드마크 | `travel.city_landmark` |
| 골목 탐방 | `activity.local_walk`, `preference.local_discovery` |
| 자연 | `place.nature_outdoor` |
| 숙소 | 없음 |
| 미식 여행 | `context.travel`, `culture.local_culture` |
| 스포츠 여행 | `preference.sports_travel`, `context.travel` |

### 예술

| UI 키워드 | mapped_concepts |
| --- | --- |
| 전시 | `culture.art_exhibition`, `place.museum_gallery` |
| 현대미술 | `culture.art_exhibition` |
| 건축 | `culture.architecture_design` |
| 공예 | `culture.history_tradition` |
| 디자인 | `culture.architecture_design` |
| 일러스트 | 없음 |
| 사진 | `mood.aesthetic` |
| 아트페어 | `culture.art_exhibition`, `context.cultural_outing` |

### 음악

| UI 키워드 | mapped_concepts |
| --- | --- |
| 인디 | 없음 |
| 재즈 | 없음 |
| 라이브 공연 | 없음 |
| 페스티벌 | `mood.lively` |
| 플레이리스트 | 없음 |
| 바이닐 | `mood.aesthetic` |
| 클래식 | 없음 |
| 사운드트랙 | 없음 |

### 스포츠

| UI 키워드 | mapped_concepts |
| --- | --- |
| 축구 | `sports.football` |
| 야구 | 없음 |
| 러닝 | `place.nature_outdoor` |
| 요가 | 없음 |
| 클라이밍 | 없음 |
| 스포츠 관람 | `activity.sports_viewing`, `sports.live_sports` |
| 경기장 투어 | `place.stadium`, `activity.sports_viewing` |
| 스포츠 여행 | `preference.sports_travel` |

### 라이프스타일

| UI 키워드 | mapped_concepts |
| --- | --- |
| 독서 | `activity.reading`, `place.bookstore` |
| 웰니스 | `mood.relaxed` |
| 작업 루틴 | `activity.study_work`, `context.daily_leisure` |
| 홈라이프 | `context.daily_leisure`, `mood.relaxed` |
| 반려생활 | 없음 |
| 취미 수집 | `mood.aesthetic` |
| 조용한 휴식 | `mood.quiet`, `preference.quiet_space` |
| 로컬 탐방 | `preference.local_discovery`, `culture.local_culture` |

## 매핑 예시

- `한옥 카페`, `전통 건축 카페` -> `한옥`, `카페`, 필요하면 `커피`
- `재즈 라이브 바`, `색소폰 공연` -> `재즈`, `라이브 공연`
- `캄프 누`, `바르셀로나 축구장` -> `축구`, `경기장 투어`, 필요하면 `스포츠 여행`
- `집에서 베이킹` -> `베이커리`, `디저트`
- `LP 수집`, `레코드샵` -> `바이닐`, 필요하면 `취미 수집`
- `감성 사진 스팟` -> `사진`, 필요하면 `랜드마크` 또는 `골목 탐방`

## 제외 규칙

아래 표현은 UI에 그대로 노출하지 않고, 가장 가까운 UI 키워드로 바꾸거나 버린다.

- 너무 구체적인 고유명사: 특정 카페명, 특정 브랜드명, 특정 팀명.
- 민감하거나 추측적인 표현: 부유함, 외로움, 건강 상태, 관계 상태.
- UI 목록에 없는 세부 취향: 베이킹, LP바, 재즈바, 성수동, 캄프 누.
- 부정 표현: 여행 싫어함, 자연 무서움, 아웃도어 안 좋아함.

가까운 UI 키워드가 없으면 `main_keywords`와 `more_signals`에 넣지 않는다.
