//
//  L10n.swift
//  翻译字典：中文作 key，提供英 / 日 / 韩 翻译
//

import Foundation

enum L10n {
    static let dict: [String: [AppLanguage: String]] = [
        // 通用
        "PhotoCleaner": [.zh: "PhotoCleaner", .en: "PhotoCleaner", .ja: "PhotoCleaner", .ko: "PhotoCleaner"],
        "整理你的照片库，腾出存储空间": [.en: "Tidy your photo library, free up space", .ja: "写真ライブラリを整理して空き容量を確保", .ko: "사진 라이브러리 정리, 저장 공간 확보"],

        // 退出确认
        "有 %d 张待删除": [
            .en: "%d Pending Delete",
            .ja: "削除予定 %d 枚",
            .ko: "삭제 대기 %d 장"
        ],
        "有待删除的照片未处理。继续退出会清空当前选择。": [
            .en: "You have unprocessed photos pending delete. Exiting will discard them.",
            .ja: "未処理の削除予定があります。退出すると選択がクリアされます。",
            .ko: "처리되지 않은 삭제 대기 사진이 있습니다. 종료하면 선택이 사라집니다."
        ],
        "继续审核": [
            .en: "Keep Reviewing",
            .ja: "続けて確認",
            .ko: "계속 검토"
        ],
        "点错了": [
            .en: "Misclicked",
            .ja: "誤タップ",
            .ko: "잘못 눌렀음"
        ],
        "放弃并退出": [
            .en: "Discard & Exit",
            .ja: "破棄して退出",
            .ko: "버리고 나가기"
        ],
        "刷新": [
            .en: "Refresh",
            .ja: "更新",
            .ko: "새로고침"
        ],
        "关闭": [.en: "Close", .ja: "閉じる", .ko: "닫기"],
        "取消": [.en: "Cancel", .ja: "キャンセル", .ko: "취소"],
        "确认": [.en: "Confirm", .ja: "確認", .ko: "확인"],
        "返回": [.en: "Back", .ja: "戻る", .ko: "뒤로"],
        "保留": [.en: "Keep", .ja: "保留", .ko: "유지"],
        "删除": [.en: "Delete", .ja: "削除", .ko: "삭제"],
        "撤销": [.en: "Undo", .ja: "取り消し", .ko: "되돌리기"],
        "信息": [.en: "Info", .ja: "情報", .ko: "정보"],
        "分享": [.en: "Share", .ja: "共有", .ko: "공유"],
        "张": [.en: " items", .ja: "枚", .ko: "장"],

        // Tab Bar
        "整理": [.en: "Sort", .ja: "整理", .ko: "정리"],
        "照片": [.en: "Photos", .ja: "写真", .ko: "사진"],
        "相簿": [.en: "Albums", .ja: "アルバム", .ko: "앨범"],
        "更多": [.en: "More", .ja: "もっと", .ko: "더보기"],

        // 问候
        "早上好": [.en: "Good Morning", .ja: "おはよう", .ko: "좋은 아침"],
        "中午好": [.en: "Good Noon", .ja: "こんにちは", .ko: "안녕하세요"],
        "下午好": [.en: "Good Afternoon", .ja: "こんにちは", .ko: "좋은 오후"],
        "晚上好": [.en: "Good Evening", .ja: "こんばんは", .ko: "좋은 저녁"],
        "夜深了": [.en: "It's late", .ja: "夜更け", .ko: "밤이 깊었어요"],

        // 首页
        "潜在可释放": [.en: "Reclaimable", .ja: "解放可能", .ko: "확보 가능"],
        "智能建议": [.en: "Smart Picks", .ja: "おすすめ", .ko: "스마트 추천"],
        "先清这些最划算": [.en: "Best value to clean first", .ja: "ここから片付けるのがお得", .ko: "여기부터 정리하면 효율적"],
        "左右滑动": [.en: "Swipe", .ja: "スワイプ", .ko: "스와이프"],
        "陈年截图": [.en: "Old Screenshots", .ja: "古いスクショ", .ko: "오래된 스크린샷"],
        "占空间大户": [.en: "Storage Hogs", .ja: "容量の大物", .ko: "용량 차지"],
        "视频清理": [.en: "Clean Videos", .ja: "動画整理", .ko: "동영상 정리"],
        "自拍清理": [.en: "Clean Selfies", .ja: "自撮り整理", .ko: "셀카 정리"],
        "时间游戏": [.en: "Time Lens", .ja: "時間の遊び", .ko: "시간 놀이"],
        "换个角度看你的相册": [.en: "See your library differently", .ja: "別の角度から見る", .ko: "다른 각도로 보기"],
        "分类": [.en: "Categories", .ja: "カテゴリ", .ko: "분류"],
        "时间线": [.en: "Timeline", .ja: "タイムライン", .ko: "타임라인"],
        "按月份回顾": [.en: "Review by month", .ja: "月別に見る", .ko: "월별 보기"],

        // 快速合集
        "随机": [.en: "Random", .ja: "ランダム", .ko: "랜덤"],
        "本周": [.en: "This Week", .ja: "今週", .ko: "이번 주"],
        "这一天": [.en: "On This Day", .ja: "今日", .ko: "오늘"],
        "去年": [.en: "Last Year", .ja: "去年", .ko: "작년"],

        // 分类
        "全部照片": [.en: "All Photos", .ja: "すべての写真", .ko: "모든 사진"],
        "全部": [.en: "All", .ja: "すべて", .ko: "전체"],
        "收藏": [.en: "Favorites", .ja: "お気に入り", .ko: "즐겨찾기"],
        "视频": [.en: "Videos", .ja: "ビデオ", .ko: "동영상"],
        "截图": [.en: "Screenshots", .ja: "スクリーンショット", .ko: "스크린샷"],
        "实况照片": [.en: "Live Photos", .ja: "Live Photos", .ko: "라이브 사진"],
        "最近添加": [.en: "Recents", .ja: "最近の項目", .ko: "최근 항목"],
        "自拍": [.en: "Selfies", .ja: "自撮り", .ko: "셀카"],
        "相机原图": [.en: "Camera Originals", .ja: "カメラ原画", .ko: "카메라 원본"],
        "社交媒体": [.en: "Social Media", .ja: "SNS", .ko: "소셜 미디어"],
        "横屏照片": [.en: "Landscape", .ja: "横向き", .ko: "가로 사진"],
        "竖屏照片": [.en: "Portrait", .ja: "縦向き", .ko: "세로 사진"],
        "大文件": [.en: "Large Files", .ja: "大容量ファイル", .ko: "큰 파일"],
        "所有未整理": [.en: "All Unsorted", .ja: "未整理すべて", .ko: "정리 안 됨"],
        "未整理的视频": [.en: "Unsorted Videos", .ja: "未整理ビデオ", .ko: "정리 안 된 동영상"],
        "未整理的截图": [.en: "Unsorted Screenshots", .ja: "未整理スクショ", .ko: "정리 안 된 스크린샷"],

        // 滑动审核
        "前一张": [.en: "Previous", .ja: "前へ", .ko: "이전"],
        "下一张": [.en: "Next", .ja: "次へ", .ko: "다음"],
        "加入待删除": [.en: "Mark Delete", .ja: "削除へ", .ko: "삭제 대기"],
        "已加入待删除": [.en: "Added to Delete", .ja: "削除に追加", .ko: "삭제에 추가됨"],
        "这个分类没有照片": [.en: "No photos in this category", .ja: "このカテゴリは空", .ko: "이 분류에 사진 없음"],
        "换一个分类试试": [.en: "Try another category", .ja: "別のカテゴリへ", .ko: "다른 분류를 시도"],
        "已审核完成": [.en: "Review Complete", .ja: "確認完了", .ko: "검토 완료"],
        "没有标记任何照片待删除。": [.en: "No photos marked for deletion.", .ja: "削除予定はありません。", .ko: "삭제 표시된 사진 없음."],
        "查看待删除列表": [.en: "View Delete List", .ja: "削除リストを見る", .ko: "삭제 목록 보기"],
        "切换分类": [.en: "Switch Category", .ja: "カテゴリ切替", .ko: "분류 전환"],
        "快速合集": [.en: "Quick Sets", .ja: "クイック集", .ko: "빠른 모음"],
        "智能分类": [.en: "Smart Categories", .ja: "スマート分類", .ko: "스마트 분류"],
        "系统相册": [.en: "System Albums", .ja: "システム", .ko: "시스템 앨범"],

        // 待删除
        "待删除": [.en: "Pending Delete", .ja: "削除予定", .ko: "삭제 대기"],
        "暂无待删除照片": [.en: "No photos to delete", .ja: "削除予定なし", .ko: "삭제할 사진 없음"],
        "上滑照片可加入此列表": [.en: "Swipe up to add", .ja: "上スワイプで追加", .ko: "위로 스와이프하여 추가"],
        "可释放": [.en: "Free up", .ja: "解放", .ko: "확보"],
        "确认删除": [.en: "Confirm Delete", .ja: "削除確認", .ko: "삭제 확인"],
        "删除中…": [.en: "Deleting…", .ja: "削除中…", .ko: "삭제 중…"],

        // 设置
        "设置": [.en: "Settings", .ja: "設定", .ko: "설정"],
        "外观": [.en: "Appearance", .ja: "外観", .ko: "외관"],
        "主题": [.en: "Theme", .ja: "テーマ", .ko: "테마"],
        "语言": [.en: "Language", .ja: "言語", .ko: "언어"],
        "跟随系统": [.en: "System", .ja: "システム", .ko: "시스템"],
        "深色": [.en: "Dark", .ja: "ダーク", .ko: "다크"],
        "浅色": [.en: "Light", .ja: "ライト", .ko: "라이트"],
        "焦糖暖": [.en: "Caramel", .ja: "キャラメル", .ko: "카라멜"],
        "冷色调": [.en: "Cool", .ja: "クール", .ko: "쿨"],

        "浏览体验": [.en: "Experience", .ja: "体験", .ko: "사용 경험"],
        "触觉反馈": [.en: "Haptics", .ja: "触覚フィードバック", .ko: "햅틱"],
        "高清缩略图": [.en: "HD Thumbnails", .ja: "高画質サムネイル", .ko: "고화질 썸네일"],
        "删除前二次确认": [.en: "Confirm Before Delete", .ja: "削除前に確認", .ko: "삭제 전 확인"],

        "数据": [.en: "Data", .ja: "データ", .ko: "데이터"],
        "已扫描照片": [.en: "Scanned Photos", .ja: "スキャン済み", .ko: "스캔됨"],
        "重新扫描分类": [.en: "Rescan Categories", .ja: "再スキャン", .ko: "재스캔"],
        "正在扫描…": [.en: "Scanning…", .ja: "スキャン中…", .ko: "스캔 중…"],
        "扫描完成": [.en: "Scan Complete", .ja: "スキャン完了", .ko: "스캔 완료"],

        "关于": [.en: "About", .ja: "について", .ko: "정보"],
        "版本": [.en: "Version", .ja: "バージョン", .ko: "버전"],
        "GitHub 仓库": [.en: "GitHub Repo", .ja: "GitHub", .ko: "GitHub"],
        "反馈问题": [.en: "Report Issue", .ja: "問題報告", .ko: "문제 신고"],
        "更新日志": [.en: "Changelog", .ja: "更新履歴", .ko: "변경 사항"],
        "发现新版本 %@": [
            .en: "Update available · %@",
            .ja: "新バージョン %@ あり",
            .ko: "새 버전 %@ 사용 가능"
        ],
        "查看更新": [.en: "Tap to view release", .ja: "リリースを見る", .ko: "릴리스 보기"],

        // 隐私
        "PhotoCleaner 在本地处理你的所有照片\n绝不上传任何数据": [
            .en: "PhotoCleaner handles all photos on-device.\nNothing is uploaded.",
            .ja: "PhotoCleaner はすべて端末内で処理\nアップロードは一切しません",
            .ko: "PhotoCleaner는 모든 사진을 기기에서 처리\n업로드 전혀 없음"
        ],

        // 权限页
        "整理你的照片库": [.en: "Tidy Your Photos", .ja: "写真を整理", .ko: "사진 정리"],
        "快速滑动审核每张照片，腾出存储空间。\n所有删除操作都需要你手动确认。": [
            .en: "Swipe through each photo to reclaim space.\nAll deletions need your confirmation.",
            .ja: "スワイプで写真を確認し、容量を解放。\n削除は必ず手動で確認します。",
            .ko: "스와이프로 각 사진을 검토하고 공간 확보.\n삭제는 수동 확인이 필요합니다."
        ],
        "允许访问照片": [.en: "Allow Photo Access", .ja: "写真へのアクセスを許可", .ko: "사진 접근 허용"],
        "无法访问照片": [.en: "Photo Access Denied", .ja: "アクセス不可", .ko: "사진 접근 불가"],
        "打开设置": [.en: "Open Settings", .ja: "設定を開く", .ko: "설정 열기"],

        // 照片浏览
        "查看大图": [.en: "View Full Size", .ja: "拡大表示", .ko: "크게 보기"],
        "照片信息": [.en: "Photo Info", .ja: "写真情報", .ko: "사진 정보"],
        "在 照片 App 中打开": [.en: "Open in Photos App", .ja: "写真 App で開く", .ko: "사진 앱에서 열기"],
        "没有符合的照片": [.en: "No matching photos", .ja: "該当する写真なし", .ko: "일치하는 사진 없음"],
        "换个筛选条件试试": [.en: "Try another filter", .ja: "別のフィルタで", .ko: "다른 필터로"],

        // 元数据
        "照片详情": [.en: "Photo Details", .ja: "写真の詳細", .ko: "사진 세부정보"],
        "文件名": [.en: "Filename", .ja: "ファイル名", .ko: "파일명"],
        "尺寸": [.en: "Size", .ja: "サイズ", .ko: "크기"],
        "大小": [.en: "File Size", .ja: "ファイルサイズ", .ko: "파일 크기"],
        "类型": [.en: "Type", .ja: "種類", .ko: "유형"],
        "创建": [.en: "Created", .ja: "作成", .ko: "생성"],
        "修改": [.en: "Modified", .ja: "変更", .ko: "수정"],
        "位置": [.en: "Location", .ja: "位置情報", .ko: "위치"],
        "时长": [.en: "Duration", .ja: "長さ", .ko: "재생시간"],
        "已收藏 ❤︎": [.en: "Favorited ❤︎", .ja: "お気に入り ❤︎", .ko: "즐겨찾기 ❤︎"],
        "未知": [.en: "Unknown", .ja: "不明", .ko: "알 수 없음"],

        // 元数据补充
        "全景照片": [.en: "Panorama", .ja: "パノラマ", .ko: "파노라마"],
        "HDR 照片": [.en: "HDR Photo", .ja: "HDR写真", .ko: "HDR 사진"],

        "将把 %d 张照片移入系统「最近删除」相册，30 天内可恢复。": [
            .en: "%d photos will move to the system Recently Deleted album, recoverable within 30 days.",
            .ja: "%d 枚を「最近削除した項目」に移動します。30 日以内に復元可能です。",
            .ko: "%d 장의 사진을 시스템 「최근 삭제됨」으로 이동, 30일 내 복원 가능."
        ],
        "删除 %d 张": [.en: "Delete %d", .ja: "%d 枚を削除", .ko: "%d 장 삭제"],

        // 横向 quick pick 提示
        "首页统计副标": [.en: "Based on %d photos", .ja: "%d 枚から推定", .ko: "%d 장 기준 추정"],
        "基于 %d 张照片估算": [.en: "Based on %d photos", .ja: "%d 枚から推定", .ko: "%d 장 기준 추정"],

        // RootView 权限
        "需要访问您的照片以便整理与释放存储空间。所有操作都需您手动确认。": [
            .en: "We need photo library access to help you tidy up. All deletions stay manual.",
            .ja: "整理と空き容量確保のため写真ライブラリへのアクセスが必要です。削除は全て手動確認です。",
            .ko: "정리와 저장 공간 확보를 위해 사진 라이브러리 접근이 필요합니다. 모든 작업은 수동 확인입니다."
        ],
        "请在「设置 → 隐私与安全性 → 照片」中允许 PhotoCleaner 访问。": [
            .en: "Allow PhotoCleaner access via Settings → Privacy → Photos.",
            .ja: "「設定 → プライバシーとセキュリティ → 写真」で PhotoCleaner を許可してください。",
            .ko: "설정 → 개인정보 보호 및 보안 → 사진 에서 PhotoCleaner 접근을 허용하세요."
        ],

        // 加载中
        "加载中…": [.en: "Loading…", .ja: "読み込み中…", .ko: "로딩 중…"],
        "扫描中…": [.en: "Scanning…", .ja: "スキャン中…", .ko: "스캔 중…"],
        "正在扫描照片库…": [.en: "Scanning photo library…", .ja: "ライブラリをスキャン中…", .ko: "라이브러리 스캔 중…"],

        // 滑动审核完成
        "已标记 %d 张待删除": [.en: "%d marked for deletion", .ja: "%d 枚を削除予定", .ko: "%d 장 삭제 대기"],

        // toast 文本（带数量的复合文案）
        "已加入待删除 · %d": [
            .en: "Marked for delete · %d",
            .ja: "削除へ追加 · %d",
            .ko: "삭제 대기에 추가 · %d"
        ],
        "扫描完成 · %d 张": [
            .en: "Scan complete · %d",
            .ja: "スキャン完了 · %d 枚",
            .ko: "스캔 완료 · %d 장"
        ],
        "刷新成功 · %d 张": [
            .en: "Refreshed · %d",
            .ja: "更新完了 · %d 枚",
            .ko: "새로고침 완료 · %d 장"
        ],
        "「%@」功能开发中": [
            .en: "“%@” coming soon",
            .ja: "「%@」開発中",
            .ko: "「%@」 개발 중"
        ],
        "设置面板开发中": [.en: "Settings panel coming soon", .ja: "設定パネルは開発中", .ko: "설정 패널 개발 중"],

        // 首页 hero/section
        "潜在可释放副标": [.en: "Potential space to free up", .ja: "空けられる容量", .ko: "확보 가능한 용량"],

        // 错误/状态文案
        "返回首页": [.en: "Back Home", .ja: "ホームへ", .ko: "홈으로"],

        // 多选
        "全选": [.en: "Select All", .ja: "全選択", .ko: "전체 선택"],
        "全不选": [.en: "Deselect All", .ja: "全解除", .ko: "전체 해제"],
        "选择": [.en: "Select", .ja: "選択", .ko: "선택"],
        "已选 %d 张": [.en: "%d Selected", .ja: "%d 枚選択", .ko: "%d 장 선택됨"],

        // 月份 + 量词
        "%d 月": [.en: "%d", .ja: "%d 月", .ko: "%d월"],

    ]
}
