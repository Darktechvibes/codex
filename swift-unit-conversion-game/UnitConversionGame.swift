import SwiftUI

struct Conversion {
    let from: String
    let to: String
    let factor: Double
    let name: String
}

struct QuestionData {
    var value: Int
    var fromUnit: String
    var toUnit: String
    var correctAnswer: Int
}

struct Score {
    var correct: Int = 0
    var wrong: Int = 0
}

struct UnitConversionGameView: View {
    @State private var answerText: String = ""
    @State private var question: QuestionData = QuestionData(value: 0, fromUnit: "", toUnit: "", correctAnswer: 0)
    @State private var feedback: String = ""
    @State private var feedbackColor: Color = .primary
    @State private var score = Score()
    @State private var funFactText: String = "Klikni na tlačítko a dozvíš se něco nového!"
    @State private var isLoading: Bool = false

    private let conversions: [Conversion] = [
        Conversion(from: "mm", to: "cm", factor: 0.1, name: "milimetry na centimetry"),
        Conversion(from: "cm", to: "mm", factor: 10, name: "centimetry na milimetry"),
        Conversion(from: "cm", to: "dm", factor: 0.1, name: "centimetry na decimetry"),
        Conversion(from: "dm", to: "cm", factor: 10, name: "decimetry na centimetry"),
        Conversion(from: "dm", to: "m", factor: 0.1, name: "decimetry na metry"),
        Conversion(from: "m", to: "dm", factor: 10, name: "metry na decimetry"),
        Conversion(from: "m", to: "cm", factor: 100, name: "metry na centimetry"),
        Conversion(from: "cm", to: "m", factor: 0.01, name: "centimetry na metry"),
        Conversion(from: "m", to: "mm", factor: 1000, name: "metry na milimetry"),
        Conversion(from: "mm", to: "m", factor: 0.001, name: "milimetry na metry"),
        Conversion(from: "km", to: "m", factor: 1000, name: "kilometry na metry"),
        Conversion(from: "m", to: "km", factor: 0.001, name: "metry na kilometry")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Převody jednotek")
                .font(.title)

            Text(questionText)
                .font(.title2)
                .frame(minHeight: 40)

            TextField("Odpověď", text: $answerText)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 140)

            HStack(spacing: 12) {
                Button("Zkontrolovat", action: checkAnswer)
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                Button("Další příklad", action: generateNewQuestion)
                    .buttonStyle(.bordered)
            }

            Text(feedback)
                .foregroundColor(feedbackColor)
                .bold()
                .frame(minHeight: 30)

            Button("✨ Zajímavost o jednotkách", action: fetchFunFact)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isLoading)

            Text(funFactText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(minHeight: 60)

            HStack {
                Text("Správně: \(score.correct) | Špatně: \(score.wrong)")
                Spacer()
                Button("Vynulovat", action: resetScore)
                    .buttonStyle(.bordered)
            }
            .padding(.top)
        }
        .padding()
        .onAppear(perform: generateNewQuestion)
    }

    private var questionText: String {
        "\(question.value) \(question.fromUnit) = ? \(question.toUnit)"
    }

    private func randomInt(_ min: Int, _ max: Int) -> Int {
        Int.random(in: min...max)
    }

    private func generateNewQuestion() {
        feedback = ""
        feedbackColor = .primary
        answerText = ""
        funFactText = "Klikni na tlačítko a dozvíš se něco nového!"
        isLoading = false

        guard let conversion = conversions.randomElement() else { return }
        var valueToConvert: Int
        var correctAnswer: Int

        if conversion.factor < 1 {
            let targetResultValue = randomInt(1, 20)
            correctAnswer = targetResultValue
            valueToConvert = Int(round(Double(targetResultValue) / conversion.factor))
        } else {
            var baseMax = 20
            if conversion.factor == 1000 { baseMax = 9 }
            else if conversion.factor == 100 { baseMax = 25 }
            else if conversion.factor == 10 { baseMax = 99 }
            valueToConvert = randomInt(1, baseMax)
            correctAnswer = Int(round(Double(valueToConvert) * conversion.factor))
        }

        question = QuestionData(value: valueToConvert,
                                 fromUnit: conversion.from,
                                 toUnit: conversion.to,
                                 correctAnswer: correctAnswer)
    }

    private func checkAnswer() {
        guard let userValue = Int(answerText.trimmingCharacters(in: .whitespaces)) else {
            feedback = "Prosím, zadej platné celé číslo."
            feedbackColor = .orange
            return
        }

        if userValue == question.correctAnswer {
            score.correct += 1
            feedback = "✅ Výborně, správně!"
            feedbackColor = .green
        } else {
            score.wrong += 1
            feedback = "❌ Škoda, špatně. Správná odpověď je: \(question.correctAnswer) \(question.toUnit)"
            feedbackColor = .red
        }
    }

    private func resetScore() {
        score = Score()
        generateNewQuestion()
    }

    private func fetchFunFact() {
        guard !isLoading else { return }
        isLoading = true
        funFactText = "Načítám zajímavost..."

        let unit1 = question.fromUnit
        let unit2 = question.toUnit
        let prompt = "Pověz mi jednu krátkou, jednoduchou a zajímavou informaci pro děti z prvního stupně základní školy o českých délkových jednotkách. Zaměř se na \(unit1) nebo \(unit2). Odpověz maximálně dvěma větami."

        let apiKey = "" // TODO: Add your Gemini API key
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            funFactText = "Neplatná URL adresa."
            isLoading = false
            return
        }

        let payload: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
            funFactText = "Nepodařilo se připravit požadavek."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    funFactText = "Chyba: \(error.localizedDescription)"
                    return
                }
                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let candidates = json["candidates"] as? [[String: Any]],
                    let content = candidates.first?["content"] as? [String: Any],
                    let parts = content["parts"] as? [[String: Any]],
                    let text = parts.first?["text"] as? String
                else {
                    funFactText = "Omlouvám se, nepodařilo se najít zajímavost."
                    return
                }
                funFactText = text
            }
        }.resume()
    }
}

struct UnitConversionGameView_Previews: PreviewProvider {
    static var previews: some View {
        UnitConversionGameView()
    }
}
