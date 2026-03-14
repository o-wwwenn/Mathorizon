import Foundation

struct DefaultQuestionLibrary {
    struct CategorySeed {
        let name: String
        let iconName: String
        let palette: CategoryPalette
        let questions: [QuestionSeed]
    }

    struct QuestionSeed {
        let prompt: String
        let choices: [String]
        let correctAnswerIndex: Int
        let explanation: String
        let difficulty: Int
    }

    static let categories: [CategorySeed] = [
        CategorySeed(
            name: "四則運算",
            iconName: "plus.forwardslash.minus",
            palette: .ocean,
            questions: [
                QuestionSeed(prompt: "18 + 27 = ?", choices: ["35", "45", "55", "65"], correctAnswerIndex: 1, explanation: "18 加 27 等於 45。", difficulty: 1),
                QuestionSeed(prompt: "84 - 39 = ?", choices: ["35", "45", "55", "65"], correctAnswerIndex: 1, explanation: "84 減 39 可先減 40 再補回 1，答案是 45。", difficulty: 2),
                QuestionSeed(prompt: "12 × 8 = ?", choices: ["84", "86", "96", "108"], correctAnswerIndex: 2, explanation: "12 乘 8 等於 96。", difficulty: 2),
                QuestionSeed(prompt: "72 ÷ 9 = ?", choices: ["6", "7", "8", "9"], correctAnswerIndex: 2, explanation: "72 除以 9 等於 8。", difficulty: 1),
                QuestionSeed(prompt: "15 + 6 × 4 = ?", choices: ["39", "64", "84", "24"], correctAnswerIndex: 0, explanation: "先算乘法 6 × 4 = 24，再加 15 得 39。", difficulty: 3)
            ]
        ),
        CategorySeed(
            name: "比例計算",
            iconName: "chart.xyaxis.line",
            palette: .jade,
            questions: [
                QuestionSeed(prompt: "2 : 3 = 8 : ?", choices: ["10", "11", "12", "13"], correctAnswerIndex: 2, explanation: "由 2 放大成 8 是乘 4，所以 3 也乘 4 得 12。", difficulty: 2),
                QuestionSeed(prompt: "一件商品打 8 折後是 240 元，原價是多少？", choices: ["280", "300", "320", "340"], correctAnswerIndex: 1, explanation: "240 是原價的 80%，所以原價是 240 ÷ 0.8 = 300。", difficulty: 3),
                QuestionSeed(prompt: "班上男生女生比是 4 : 5，若男生有 20 人，女生有幾人？", choices: ["22", "24", "25", "28"], correctAnswerIndex: 2, explanation: "4 對應 20，放大 5 倍，所以女生是 5 × 5 = 25。", difficulty: 2),
                QuestionSeed(prompt: "地圖比例尺 1 : 1000，圖上 7 公分代表實際多少公分？", choices: ["700", "7000", "70", "70,000"], correctAnswerIndex: 1, explanation: "7 × 1000 = 7000 公分。", difficulty: 2),
                QuestionSeed(prompt: "果汁濃縮液與水的比例是 1 : 4，若要調出 25 杯，濃縮液要幾杯？", choices: ["4", "5", "6", "7"], correctAnswerIndex: 1, explanation: "總份數 5 份，25 杯平均每份 5 杯，濃縮液需要 5 杯。", difficulty: 3)
            ]
        ),
        CategorySeed(
            name: "分數運算",
            iconName: "divide.circle",
            palette: .amber,
            questions: [
                QuestionSeed(prompt: "1/2 + 1/3 = ?", choices: ["2/5", "3/5", "5/6", "1"], correctAnswerIndex: 2, explanation: "通分成 3/6 + 2/6 = 5/6。", difficulty: 2),
                QuestionSeed(prompt: "3/4 - 1/8 = ?", choices: ["1/2", "5/8", "3/8", "7/8"], correctAnswerIndex: 1, explanation: "3/4 = 6/8，6/8 - 1/8 = 5/8。", difficulty: 2),
                QuestionSeed(prompt: "2/3 × 3/5 = ?", choices: ["1/5", "2/5", "3/8", "6/15"], correctAnswerIndex: 1, explanation: "分子分母相乘後約分，得到 2/5。", difficulty: 3),
                QuestionSeed(prompt: "4/5 ÷ 2/3 = ?", choices: ["6/5", "5/6", "8/15", "12/10"], correctAnswerIndex: 0, explanation: "除以 2/3 等於乘以 3/2，4/5 × 3/2 = 12/10 = 6/5。", difficulty: 4),
                QuestionSeed(prompt: "1 又 1/2 + 2 又 1/4 = ?", choices: ["3 又 1/2", "3 又 3/4", "4", "4 又 1/4"], correctAnswerIndex: 1, explanation: "整數相加是 3，分數相加是 1/2 + 1/4 = 3/4。", difficulty: 3)
            ]
        ),
        CategorySeed(
            name: "代數",
            iconName: "x.squareroot",
            palette: .indigo,
            questions: [
                QuestionSeed(prompt: "若 x + 7 = 19，則 x = ?", choices: ["10", "11", "12", "13"], correctAnswerIndex: 2, explanation: "將 7 移到右邊，19 - 7 = 12。", difficulty: 1),
                QuestionSeed(prompt: "2x = 18，則 x = ?", choices: ["7", "8", "9", "10"], correctAnswerIndex: 2, explanation: "18 ÷ 2 = 9。", difficulty: 1),
                QuestionSeed(prompt: "3x + 5 = 20，則 x = ?", choices: ["3", "4", "5", "6"], correctAnswerIndex: 2, explanation: "先減 5 得 15，再除以 3 得 5。", difficulty: 2),
                QuestionSeed(prompt: "若 y = 4，則 2y² = ?", choices: ["8", "16", "24", "32"], correctAnswerIndex: 3, explanation: "y² = 16，再乘 2 得 32。", difficulty: 2),
                QuestionSeed(prompt: "5a - 3 = 2a + 12，則 a = ?", choices: ["3", "4", "5", "6"], correctAnswerIndex: 2, explanation: "移項得 3a = 15，所以 a = 5。", difficulty: 4)
            ]
        )
    ]
}
