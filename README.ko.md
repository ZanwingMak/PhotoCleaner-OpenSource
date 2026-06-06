# PhotoCleaner

[中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · **한국어**

> Slidebox 스타일의 iOS 사진 정리 도구. 네이티브 SwiftUI, iOS 26 리퀴드 글래스.

![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-blue)

## 기능

- 📷 시스템 사진 라이브러리 읽기, 스마트 앨범 + 메타데이터로 분류
- 👉 **스와이프로 검토**: 왼쪽 = 다음 / 오른쪽 = 이전 / 위 = 삭제 대기에 추가
- 🗑 **삭제 대기 목록** 일괄 확인 + iOS 시스템 삭제 대화상자
- ⏪ 한 단계 되돌리기
- 🖼 **사진 브라우저**: 전체 화면, 줌, 좌우 페이지 전환, 즐겨찾기 / 공유 / 사진 앱으로 이동
- 📊 **메타데이터 시트**: 크기, 파일 크기, 종류, 위치, 재생시간
- 🌗 **5가지 테마**: 시스템 / 다크 / 라이트 / 카라멜 / 쿨
- 🌐 **4개 언어**: 中文 / English / 日本語 / 한국어
- ✨ iOS 26 리퀴드 글래스 + 전용 AppIcon
- 🔒 100% 기기 내 처리, 업로드 없음

## 프로젝트 구조

[中文 README](README.md#项目结构) 참조 (동일).

## 시뮬레이터에서 실행

```bash
# Xcode 26+ 와 iOS Simulator runtime 필요
open PhotoCleaner.xcodeproj
# Xcode 에서 ⌘R
```

## 미서명 IPA 빌드

```bash
bash scripts/build-ipa.sh
# 결과물: build/PhotoCleaner-v<VERSION>.ipa
```

## 실기기에 설치 (개발자 계정 없이)

IPA 는 미서명. 다음 중 하나로 무료 Apple ID 로 자체 서명 (인증서 7일 유효):

### 방법 A: Sideloadly (가장 간단)
1. https://sideloadly.io 다운로드
2. `build/PhotoCleaner-v0.8.0.ipa` 끌어다 놓기
3. 무료 Apple ID 입력
4. iPhone: 설정 → 일반 → VPN 및 기기 관리 → 인증서 신뢰

### 방법 B: AltStore (자동 갱신)
AltServer 를 백그라운드에서 실행하여 7일 인증서 자동 갱신

### 방법 C: Xcode 직접 서명
Xcode 에서 프로젝트 열고 Signing → Team 에 무료 Apple ID 선택, ⌘R 로 실기기에 실행

## 개인정보

- 모든 처리는 기기 내. **업로드 전혀 없음**
- `NSPhotoLibraryUsageDescription` 만 요청
- 삭제 시 iOS 시스템 대화상자가 표시되며, 앱은 이를 우회할 수 없음

## 링크

- [변경 사항 CHANGELOG.md](CHANGELOG.md)
- [기능 명세 FEATURES.md](FEATURES.md)
- [테스트 계획 TEST_PLAN.md](TEST_PLAN.md)
- [Releases](https://github.com/ZanwingMak/PhotoCleaner/releases)

## 라이선스

MIT
