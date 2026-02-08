### NoIll App Design System for Web/App Collaboration

이 가이드는 Flutter의 `AppTheme` 설정을 React(Web) 환경으로 이식하기 위한 상세 명세입니다.

추가로 디자인 변경 시 최우선으로 고려할 사항은 노인이 사용하는 디스플레이 임을 감안해서 가독성이 좋게 사용하기 쉽게 만들어야 합니다.

## 1. 전역 설정 (Global Styles)

- **Font Family**: `Pretendard`, -apple-system, BlinkMacSystemFont, system-ui, Roboto, sans-serif
- **Background Color**: `#FDFBF7` (Milky Ivory / `NoIllColors.background`)
- **Base Spacing Unit**: `8px` (모든 간격은 8의 배수를 권장합니다.)

## 2. 컬러 팔레트 (Design Tokens - Colors)

React 개발자가 CSS Variable로 정의하기 편하도록 HEX 코드로 정리했습니다.

| **Token Name** | **HEX Code** | **Flutter Variable** | **Usage** |
| --- | --- | --- | --- |
| **Primary** | `#FF4B4B` | `NoIllColors.primary` | 브랜드 메인 컬러, 핵심 액션 버튼 |
| **Danger** | `#E53935` | `NoIllColors.danger` | 사고 알림, 에러 메시지, 경고 |
| **Background** | `#FDFBF7` | `NoIllColors.background` | 전체 화면 배경 (밀키 아이보리) |
| **Surface** | `#FFFFFF` | `NoIllColors.surface` | 카드 배경, 흰색 면적 |
| **Border** | `#E0E0E0` | `NoIllColors.border` | 입력창 테두리, 구분선 |
| **Text-Main** | `#212529` | `NoIllColors.textMain` | 제목, 주요 본문 (Deep Charcoal) |
| **Text-Body** | `#495057` | `NoIllColors.textBody` | 보조 설명, 캡션 텍스트 |

---

## 3. 타이포그래피 (Typography)

웹의 `rem` 또는 `px` 단위로 변환한 명세입니다.

- **H1 (Display Large)**
    - Size: `20px` (1.25rem)
    - Weight: `700` (Bold)
    - Line Height: `1.4`
    - Color: `#212529`
- **Body (Body Large)**
    - Size: `16px` (1rem)
    - Weight: `500` (Medium)
    - Line Height: `1.5`
    - Color: `#212529`
- **Caption (Label Small)**
    - Size: `14px` (0.875rem)
    - Weight: `400` (Regular)
    - Line Height: `1.5`
    - Color: `#495057`

---

## 4. 컴포넌트 상세 명세 (Component Specs)

### ① 카드 (Information Card)

Flutter의 `CardTheme`를 CSS로 변환한 값입니다.

- **Background**: `#FFFFFF`
- **Border Radius**: `16px`
- **Padding**: `16px` (추천)
- **Box Shadow**: `0px 4px 10px rgba(0, 0, 0, 0.1)`
- **Margin**: `8px`

### ② 버튼 (Primary Action Button)

React의 `styled-components`나 `Tailwind` 적용 기준입니다.

- **Background**: `#FF4B4B` (`primary`)
- **Text Color**: `#FFFFFF`
- **Height**: `52px`
- **Width**: `100%` (`double.infinity`)
- **Border Radius**: `24px`
- **Typography**: `16px / 600` (Semi-bold 권장)

### ③ 입력창 (Input Decoration)

- **Background**: `#FFFFFF` (Surface)
- **Padding**: `16px 16px`
- **Border Radius**: `8px`
- **Border**: `1px solid #E0E0E0`
- **Focus State**: `2px solid #FF4B4B` (Primary)