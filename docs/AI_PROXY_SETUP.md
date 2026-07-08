# LOGZINE AI Proxy Setup

## 현재 구조 (2026-07-08부터: Firebase Cloud Functions)

```text
Flutter app -> Firebase Cloud Functions (us-central1) -> Gemini API
```

팀은 하나의 유료 Gemini API 키를 공유하며, 키는 저장소·앱 빌드에 절대 포함되지
않고 Google Secret Manager(`GEMINI_API_KEY`)에만 저장된다.

### 왜 Cloudflare Worker에서 이전했나

Cloudflare Worker는 요청마다 다른 엣지 서버에서 실행되는데, Google이 일부
Cloudflare IP(아시아권)를 미지원 지역으로 판정해
`FAILED_PRECONDITION: User location is not supported` 오류가 간헐적으로
발생했다 (같은 코드가 어떨 땐 되고 어떨 땐 안 되던 원인). Cloud Functions는
미국 리전(us-central1)의 Google IP에서 실행되므로 이 문제가 원천적으로 없다.
Smart Placement 등 Cloudflare 쪽 우회는 실측 결과 효과가 없었다.

`logzine_app/cloudflare-worker/`는 기록용으로만 남아 있으며 더 이상 사용하지
않는다.

## 배포된 프록시 주소

```text
https://us-central1-logzine-c8905.cloudfunctions.net/geminiProxy
```

## 검증 상태 (2026-07-08)

프록시를 통해 아래 4종을 실호출로 확인 완료:

- 텍스트 생성 (봉투 형식, `gemini-flash-latest`)
- 텍스트 생성 (REST 경로 형식, `gemini-2.5-flash`)
- 이미지 분석 Vision (취향 분석용)
- 이미지 생성 `gemini-2.5-flash-image` (MY COVER용, 1.5MB PNG 생성 확인)

## 지원 요청 형식 (Worker 시절과 동일 — 앱 코드 수정 불필요)

봉투(envelope) 형식:

```http
POST /
```

```json
{
  "model": "gemini-2.5-flash",
  "body": { "contents": [] }
}
```

Gemini REST 유사 경로:

```http
POST /v1beta/models/gemini-2.5-flash:generateContent
```

```json
{ "contents": [] }
```

허용 모델: `gemini-2.5-flash`, `gemini-flash-latest`, `gemini-2.5-flash-image`
(⚠️ `gemini-2.0-flash`는 Google에서 단종되어 404가 반환됨)

## 팀원 실행 방법

`logzine_app/env.json` 생성/수정 (`env.example.json` 복사):

```json
{
  "GEMINI_PROXY_URL": "https://us-central1-logzine-c8905.cloudfunctions.net/geminiProxy"
}
```

실행:

```powershell
cd logzine_app
flutter run -d chrome --dart-define-from-file=env.json
```

팀원은 Gemini 키도, Firebase 콘솔 접근 권한도 필요 없다.

## 프록시 재배포 (프록시 소유자만)

코드는 `logzine_app/functions/index.js`.

```powershell
cd logzine_app
npx firebase-tools deploy --only functions --project logzine-c8905
```

키 교체 시:

```powershell
npx firebase-tools functions:secrets:set GEMINI_API_KEY --project logzine-c8905
npx firebase-tools deploy --only functions --project logzine-c8905
```

## 비용 안전장치

- Blaze 요금제이지만 Functions 무료 할당량(월 200만 호출)이 커서 데모
  트래픽으로는 사실상 0원. Gemini 사용료는 키 소유자의 Google AI 결제로 나감.
- 함수에 `maxInstances: 5` 설정 → 트래픽 폭주로 인한 과금 차단
- 컨테이너 이미지 1일 자동 정리 정책 설정됨 (`functions:artifacts:setpolicy`)
- Firebase 콘솔에 예산 알림 설정됨

## 한계

데모용 설정으로 인증 없이 공개되어 있다. 실서비스 전에는 App Check, 사용자
인증 헤더 검증, 레이트 리미팅 등 남용 방지 장치를 추가해야 한다.
