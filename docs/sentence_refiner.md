---
name: taste-keyword-refiner
description: 사진 분석으로 추출된 취향 후보 키워드, 사용자가 선택하거나 해제한 키워드, 사용자가 자유롭게 작성한 줄글 피드백을 병합해 UI 노출 키워드 목록 안에서만 최종 관심분야 키워드와 제외 키워드를 확정할 때 사용한다. 이미지 기반 추천앱, 매거진 추천, 라이프스타일 취향 프로필, 태그 보정 UI, "나는 축구도 좋아해", "여행은 싫어해"처럼 사용자가 키워드 선택과 자연어로 선호/비선호를 수정하는 기능을 설계, 구현, 검토, 프롬프팅할 때 사용한다. 사진 분석 키워드와 사용자 줄글이 상충하면 사용자 줄글을 우선한다.
---

# Taste Keyword Refiner

## 목적

사진 분석 결과는 최종 취향이 아니라 사용자가 수정할 수 있는 초안으로 다룬다. 이 스킬은 AI 후보 키워드, 사용자의 선택/해제 상태, 줄글 피드백을 하나의 최종 관심분야 키워드 목록으로 정제한다.

가장 중요한 원칙은 사용자 피드백이 AI 추정보다 항상 우선한다는 것이다.

최종 결과는 자유 키워드가 아니라 `photo-taste-analyzer/references/ui_keyword_vocabulary.md`에 정의된 UI 키워드 목록 안에서만 정규화한다. 내부 추천 매칭에는 각 UI 키워드의 `mapped_concepts`를 사용한다.

UI 키워드 목록에 없는 표현은 `main_keywords`에도 `more_signals`에도 내보내지 않는다. 가장 가까운 UI 키워드가 있으면 그 키워드로 바꾸고, 가까운 항목이 없으면 앱 화면 출력에서 제외한다.

## 입력으로 받기

가능하면 아래 네 종류의 입력을 분리해서 받는다.

```json
{
  "ai_keywords": [
    { "ui_keyword": "도시 여행", "category": "TRAVEL", "mapped_concepts": ["context.travel", "travel.city_landmark"] },
    { "ui_keyword": "카페", "category": "FOOD", "mapped_concepts": ["place.cafe", "food_drink.coffee"] },
    { "ui_keyword": "전시", "category": "ART", "mapped_concepts": ["culture.art_exhibition", "place.museum_gallery"] },
    { "ui_keyword": "자연", "category": "TRAVEL", "mapped_concepts": ["place.nature_outdoor"] },
    { "ui_keyword": "조용한 휴식", "category": "LIFESTYLE", "mapped_concepts": ["mood.quiet", "preference.quiet_space"] }
  ],
  "selected_keywords": ["도시 여행", "카페", "전시", "조용한 휴식"],
  "deselected_keywords": ["자연"],
  "free_text_feedback": "I also like playing soccer. 사실 여행은 싫어해."
}
```

`selected_keywords`와 `deselected_keywords`에는 UI 키워드 문자열을 넣는다. 내부 저장이 필요하면 `ui_keyword_vocabulary.md`의 `mapped_concepts`로 변환한다.

`selected_keywords`와 `deselected_keywords`가 없고 최종 클릭 상태만 있으면, AI 후보와 비교해 선택/해제 상태를 계산한다. 클릭 상태가 불명확하거나 줄글과 충돌하면 줄글 피드백을 더 강한 근거로 사용한다.

## 처리 순서

1. AI 후보를 초안으로 놓는다.
2. 사용자가 해제한 키워드는 최종 관심 키워드에서 제거한다.
3. 사용자가 새로 선택하거나 추가한 키워드는 높은 신뢰도로 포함한다.
4. 줄글 피드백에서 선호, 비선호, 정정, 강도, 맥락을 추출한다.
5. 줄글에서 추출한 문장 조각을 가장 가까운 UI 키워드로 매핑한다.
6. 줄글의 부정/정정 표현이 사진 분석 키워드나 클릭 상태와 충돌하면 줄글을 우선한다.
7. 중복, 상하위어, 너무 넓은 키워드를 정리하되, 최종 키워드는 UI 키워드 목록에 있는 값만 남긴다.
8. 최종 관심 키워드, 제외 키워드, 하향 키워드, More signals, 사용자 원문을 함께 출력한다.

## UI 표시 계약

최종 프로필 화면의 메인 키워드 칩에는 `main_keywords[].ui_keyword`만 사용한다. `user_text`, `add`, `remove`, `negative_signals`, `profile_update_summary`를 메인 칩으로 표시하지 않는다.

앱은 사용자의 줄글을 자체적으로 키워드화하지 않는다. 줄글의 의미 해석, 추가/삭제/하향 판단, 최종 키워드 확정은 이 스킬의 출력이 담당한다. 앱은 `main_keywords[].ui_keyword`를 렌더링하고, 저장은 `ui_keyword`, `category`, `mapped_concepts` 기준으로 한다.

`main_keywords[].ui_keyword`는 UI 키워드 목록에 정의된 사용자 표시 라벨이어야 한다. 자유롭게 새 라벨을 만들지 않는다.

앱 화면은 세 덩어리로 단순화한다.

- `main_keywords`: UI 키워드 목록 안의 메인 관심 키워드. 추천 매칭과 프로필 저장에는 `mapped_concepts`를 함께 사용한다.
- `more_signals`: UI 키워드 목록 안에서 헷갈리거나 보조적인 키워드만 넣는다. 목록 밖 표현은 넣지 않는다.
- `user_text`: 사용자가 작성한 줄글 원문. 재분석과 충돌 해결의 가장 강한 근거로 보관한다.

앱 기능에는 `needs_review`와 `clarifying_question`을 사용하지 않는다. 애매한 표현도 UI 목록 안에 있는 키워드일 때만 `more_signals`에 넣는다.

허용:

- `로컬 문화`
- `문화 외출`
- `조용한 분위기`
- `도시 랜드마크`
- `카페`

금지:

- `나는 도시탐험을`
- `하고 아웃도어는 안`
- `나는 도시탐험을 좋아하고 아웃도어...`
- `아웃도어는 안`
- `여행은 싫어해`
- `도시탐험을 하고 싶어`

아래 문자열이 들어간 항목은 최종 칩으로 내보내지 않는다. 이런 표현은 먼저 UI 키워드로 매핑하거나 제외/하향 신호로 바꾼다.

- 1인칭 표현: `나는`, `제가`, `내가`, `I`, `I'm`, `I like`.
- 미완성 조사/어미: `을`, `를`, `은`, `는`, `하고`, `좋아하고`, `안`.
- 부정문: `싫어`, `안 좋아`, `관심 없어`, `not into`, `don't like`.
- 말줄임표 또는 잘린 텍스트: `...`, `…`.

금지 항목이 생기면 문장을 그대로 자르지 말고 의미를 다시 해석해 UI 키워드로 정규화한다. 정규화가 불가능하거나 UI 목록에 가까운 항목이 없으면 앱 화면 출력에서 제외한다.

## 우선순위 규칙

우선순위는 다음 순서로 적용한다.

1. 사용자가 명시한 비선호 또는 부정: `싫어`, `아니야`, `관심 없어`, `제외`, `빼줘`, `doesn't interest me`, `not into`.
2. 사용자가 명시한 선호 또는 추가: `좋아해`, `관심 있어`, `추가`, `also like`, `want more`.
3. 사용자가 해제한 키워드.
4. 사용자가 선택한 키워드.
5. AI가 추출한 후보 키워드.

예를 들어 사용자가 `여행` 칩을 선택한 상태여도 줄글에 `사실 여행은 싫어해`라고 쓰면 최종 관심 키워드에서 `여행`을 제거하고 제외 키워드에 넣는다.

사진 분석에서 `context.travel`이 높은 신뢰도로 들어왔더라도, 사용자가 줄글로 `여행은 아니고 동네에서 쉰 거야`라고 쓰면 `context.travel`은 제외하거나 하향하고 `context.daily_leisure`, `mood.relaxed`처럼 사용자 줄글과 맞는 concept을 우선한다.

## 줄글 피드백 해석

줄글에서 다음 신호를 추출한다.

- `add`: 새롭게 추가할 관심사.
- `remove`: 최종 키워드에서 제거할 항목.
- `downweight`: 완전히 싫어하는 것은 아니지만 추천 강도를 낮출 항목.
- `rename`: 사용자가 더 정확한 표현으로 고친 항목.
- `focus`: 같은 사진 안에서 더 중요한 기준.
- `context`: 일상, 여행, 업무, 취미, 운동처럼 추천 맥락을 바꾸는 정보.

예시:

`나는 축구도 좋아해. 사실 여행은 싫어해. 조용한 카페는 좋아.`

```json
{
  "add": ["축구", "카페", "조용한 휴식"],
  "remove": ["도시 여행", "해외 도시", "스포츠 여행"],
  "downweight": [],
  "focus": ["축구", "조용한 휴식"],
  "negative_signals": ["여행 비선호"]
}
```

## 문장 조각 정규화

사용자 문장을 키워드로 만들 때는 원문을 토큰 단위로 자르지 않는다. 반드시 의미 단위로 변환한다.

예시:

- `나는 도시탐험을 좋아하고 아웃도어는 안 좋아해` -> 최종 `골목 탐방`, `로컬 탐방`; 제외 `자연`.
- `I also like playing soccer` -> 최종 `축구`. 직접 하는 축구인지 관람인지 불명확하면 `스포츠 관람`은 넣지 않는다.
- `여행은 싫고 도시에서 노는 게 좋아` -> 최종 `골목 탐방`, `로컬 탐방`; 제외 `도시 여행`, `해외 도시`, `스포츠 여행`.
- `문화생활은 좋은데 등산은 별로야` -> 최종 `전시`, `전시 공간`, `복합문화공간`; 제외 또는 하향 `자연`.
- `카페는 분위기 때문에 좋아` -> 최종 `카페`, `인테리어`, `조용한 휴식`.
- `나 벌레를 무서워해서 자연은 싫어` -> 최종 추가 없음; 제외 또는 하향 `자연`.

원문에 선호와 비선호가 같이 있으면 최종 키워드에는 선호만 넣고, 비선호는 `excluded_keywords`에 넣는다.

`무서워`, `두려워`, `겁나`, `싫어`, `안 좋아`, `별로`처럼 회피나 비선호를 나타내는 문장은 절대 `main_keywords`에 넣지 않는다. 예를 들어 `나 벌레를 무서워`는 `벌레`나 `나 벌레를 무서워`라는 관심 키워드가 아니라 UI 키워드 `자연` 계열 추천을 줄이라는 부정 신호다.

## 키워드 확장 규칙

사용자가 구체적 관심사를 말하면 추천에 도움이 되는 상위/연관 키워드를 소수만 추가한다.

- `축구도 좋아해` -> `축구`. 경기 관람 맥락이 있으면 `스포츠 관람`도 추가한다.
- `베이킹 배우고 싶어` -> 가장 가까운 UI 키워드 `베이커리` 또는 `디저트`로 매핑한다. `베이킹`은 UI 목록 밖이므로 출력하지 않는다.
- `전시 보는 걸 좋아해` -> `전시`, `전시 공간`, 필요하면 `복합문화공간`.

확장은 2-4개로 제한한다. 사용자의 말보다 과도하게 넓히지 않는다. `축구`를 `스포츠 관람`, `스포츠 여행`, `경기장 투어`까지 자동 확장하지 않는다. 사진이나 줄글에 경기장/직관/여행 단서가 있을 때만 추가한다.

## 제거 규칙

부정 피드백은 넓게 반영하되 과잉 제거하지 않는다.

- `여행은 싫어해` -> `도시 여행`, `해외 도시`, `스포츠 여행` 제거 또는 하향.
- `밖에 나가는 건 별로야` -> `자연`, `골목 탐방`, `러닝`은 하향 또는 제거. 단, 사용자가 `축구는 좋아해`라고 함께 말하면 `축구`는 유지한다.
- `카페 사진은 그냥 장소가 예뻐서 찍은 거야` -> `카페`, `커피`는 하향하고 `인테리어`, `디자인`, `조용한 휴식`을 유지할 수 있다.

최종 키워드에서 제거한 항목은 `excluded_keywords`에 이유와 함께 남긴다. 이렇게 해야 다음 추천에서 같은 오류가 반복되지 않는다.

## 충돌 해결

충돌은 사용자 의도가 더 구체적이고 최신인 쪽을 따른다.

- 선택 칩 `도시 여행` + 줄글 `여행은 싫어해` -> `도시 여행` 제거.
- 해제 칩 `자연` + 줄글 `공원 산책은 좋아해` -> 넓은 `자연`은 제외/하향하고 `골목 탐방` 또는 `로컬 탐방`은 추가한다.
- AI 후보 `전시` + 줄글 `예술보다는 건축물이 좋아` -> `전시`를 하향하고 `건축`을 추가한다.
- 줄글 `축구 보는 건 좋아하지만 직접 하는 건 싫어` -> `축구`, `스포츠 관람` 추가. `축구하기`는 UI 목록 밖이므로 출력하지 않는다.

## 최종 출력 형식

기능 설계나 프롬프트 결과는 아래 구조를 사용한다.

```json
{
  "main_keywords": [
    {
      "ui_keyword": "축구",
      "category": "SPORTS",
      "mapped_concepts": ["sports.football"],
      "source": "free_text_feedback",
      "confidence": 0.96,
      "reason": "사용자가 축구를 좋아한다고 직접 언급함"
    },
    {
      "ui_keyword": "카페",
      "category": "FOOD",
      "mapped_concepts": ["place.cafe", "food_drink.coffee"],
      "source": "selected_keyword_and_feedback",
      "confidence": 0.9,
      "reason": "기존 카페 후보와 사용자의 카페 선호가 함께 확인됨"
    },
    {
      "ui_keyword": "조용한 휴식",
      "category": "LIFESTYLE",
      "mapped_concepts": ["mood.quiet", "preference.quiet_space"],
      "source": "free_text_feedback",
      "confidence": 0.88,
      "reason": "사용자가 조용한 카페를 좋아한다고 언급함"
    }
  ],
  "more_signals": [],
  "user_text": "I also like playing soccer. 사실 여행은 싫어해. 조용한 카페는 좋아.",
  "excluded_keywords": [
    {
      "ui_keyword": "도시 여행",
      "category": "TRAVEL",
      "mapped_concepts": ["context.travel", "travel.city_landmark"],
      "source": "free_text_feedback",
      "reason": "사용자가 여행을 싫어한다고 명시함"
    }
  ],
  "downweighted_keywords": [
    {
      "ui_keyword": "자연",
      "category": "TRAVEL",
      "mapped_concepts": ["place.nature_outdoor"],
      "reason": "사용자가 칩을 해제했지만 관련 세부 선호는 아직 불명확함"
    }
  ],
  "profile_update_summary": "축구와 조용한 카페 선호를 추가하고, 여행 관련 추천 신호를 제외합니다."
}
```

`main_keywords[].ui_keyword`는 UI 메인 칩에 바로 써도 되는 UI 키워드만 담는다. 이 배열에는 문장, 부정 표현, 이유, 요약문, 원문 일부를 넣지 않는다.

`main_keywords`, `excluded_keywords`, `downweighted_keywords`의 각 항목에는 `ui_keyword`, `category`, `mapped_concepts`를 가능한 한 포함한다. `mapped_concepts`가 비어 있어도 `ui_keyword`는 반드시 UI 키워드 목록 안의 값이어야 한다.

`more_signals`는 UI 키워드 문자열 배열로 둔다. 예: `["재즈", "라이브 공연", "베이커리"]`. 이 값은 메인 키워드보다 약한 신호이며, UI 목록 밖 표현은 절대 넣지 않는다.

## 키워드 타입

타입은 추천 시스템이 다르게 사용할 수 있도록 구분한다.

- `interest`: 축구, 전시, 베이커리 같은 관심 분야.
- `activity`: 로컬 산책, 독서, 스포츠 관람, 카페에서 쉬기 같은 행동.
- `place_type`: 카페, 미술관, 공원, 경기장 같은 장소.
- `mood`: 조용한, 활기찬, 감성적인, 여유로운 같은 분위기.
- `preference`: 조용한 공간 선호, 문화+카페 경험, 스포츠 여행처럼 누적 프로필에 가까운 표현.
- `negative_signal`: 여행 비선호, 야외활동 제외처럼 추천에서 피해야 할 신호.

최종 저장 타입은 `category`와 `mapped_concepts`를 따른다. 현재 UI 키워드 목록에 없는 `content` 같은 타입은 최종 키워드로 새로 만들지 않는다.

## 최종 키워드 품질 기준

최종 키워드는 짧고 추천 가능한 표현이어야 한다.

- 한 키워드는 UI 키워드 목록의 `ui_keyword`를 사용한다. 문장은 금지한다.
- 사용자 원문이 영어이면 UI 키워드 목록 안의 한국어 키워드로 정규화하되 원문 의미를 보존하고, 내부 추천은 `mapped_concepts`로 한다.
- 중복 표현은 UI 키워드와 concept 기준으로 합친다: `카페`, `커피`, `조용한 카페`가 함께 있으면 `카페`, `커피`, `조용한 휴식`처럼 UI 키워드 목록 안에서 분리한다.
- 너무 넓은 키워드는 사용자가 직접 원하지 않는 한 피한다: `라이프스타일`, `취미`, `콘텐츠`.
- 민감한 개인정보, 성격 단정, 경제 수준, 건강, 종교, 정치, 관계 상태는 키워드화하지 않는다.
- 최종 라벨은 조사로 끝나지 않는다. `을`, `를`, `은`, `는`, `이`, `가`, `하고`, `안`으로 끝나면 실패로 보고 다시 정규화한다.
- 최종 라벨은 사용자 발화를 요약한 문장이 아니다. `나는 ... 좋아해`는 `...`만 관심 키워드로 바꾼다.
- UI 키워드 목록에 없는 새 표현은 임의 라벨로 저장하지 않는다. 가까운 UI 키워드가 있을 때만 `main_keywords`나 `more_signals`에 넣고, 없으면 UI 출력에서 제외한다.

## 구현 아이디어

완성도를 높이려면 다음 기능을 함께 설계한다.

- 키워드마다 `source`를 저장한다: `ai`, `selected_chip`, `deselected_chip`, `free_text_feedback`.
- 사용자 피드백에는 `timestamp`와 `feedback_session_id`를 붙여 최신 의도를 우선한다.
- 제외 키워드는 삭제하지 말고 별도 저장한다. 추천에서 피해야 할 신호로 매우 중요하다.
- 한 번의 사진 피드백은 `session_preferences`로 저장하고, 반복 확인된 항목만 장기 `preference_profile`로 승격한다.
- 부정 신호는 추천 차단 강도를 둔다: `hard_exclude`, `soft_downweight`.
- 다국어 입력을 허용하고 최종 키워드는 서비스 기본 언어로 정규화한다.
- 사용자가 고친 결과를 다음 이미지 분석의 후보 생성 프롬프트에 반영한다.

## 최소 테스트 케이스

구현이나 프롬프트를 검토할 때 아래 케이스를 통과해야 한다.

입력:

```json
{
  "ai_keywords": [
    { "ui_keyword": "로컬 탐방", "category": "LIFESTYLE", "mapped_concepts": ["preference.local_discovery", "culture.local_culture"] },
    { "ui_keyword": "자연", "category": "TRAVEL", "mapped_concepts": ["place.nature_outdoor"] },
    { "ui_keyword": "복합문화공간", "category": "SPACE", "mapped_concepts": ["context.cultural_outing", "culture.local_culture"] },
    { "ui_keyword": "홈라이프", "category": "LIFESTYLE", "mapped_concepts": ["context.daily_leisure", "mood.relaxed"] }
  ],
  "selected_keywords": ["로컬 탐방", "복합문화공간", "자연"],
  "deselected_keywords": [],
  "free_text_feedback": "나는 도시탐험을 좋아하고 아웃도어는 안 좋아해"
}
```

올바른 출력:

```json
{
  "main_keywords": [
    { "ui_keyword": "로컬 탐방", "category": "LIFESTYLE", "mapped_concepts": ["preference.local_discovery", "culture.local_culture"] },
    { "ui_keyword": "복합문화공간", "category": "SPACE", "mapped_concepts": ["context.cultural_outing", "culture.local_culture"] },
    { "ui_keyword": "골목 탐방", "category": "TRAVEL", "mapped_concepts": ["activity.local_walk", "preference.local_discovery"] }
  ],
  "more_signals": [],
  "user_text": "나는 도시탐험을 좋아하고 아웃도어는 안 좋아해",
  "excluded_keywords": [
    { "ui_keyword": "자연", "category": "TRAVEL", "mapped_concepts": ["place.nature_outdoor"], "reason": "사용자가 아웃도어를 좋아하지 않는다고 명시함" }
  ]
}
```

잘못된 출력:

```json
{
  "main_keywords": [
    { "ui_keyword": "나는 도시탐험을" },
    { "ui_keyword": "하고 아웃도어는 안" },
    { "ui_keyword": "나는 도시탐험을 좋아하고 아웃도어..." }
  ]
}
```

잘못된 출력이 나온 경우 원인은 키워드 정제가 아니라 문장 분할 또는 원문 요약을 칩으로 사용한 것이다. 이때 프롬프트와 UI 매핑을 모두 점검한다.

## 안전 경계

사용자가 직접 말하지 않은 민감한 속성은 생성하지 않는다. 사진 속 사람, 위치, 생활 수준, 건강, 정체성, 관계에 대한 추측을 최종 관심 키워드로 만들지 않는다.

확신이 낮은 AI 후보보다 사용자 피드백을 우선하고, 불확실한 내용은 최종 키워드가 아니라 확인 질문이나 하향 키워드로 둔다.
