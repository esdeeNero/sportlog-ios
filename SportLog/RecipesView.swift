import SwiftUI

struct Recipe: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let calories: Int
    let category: String
    let meal: String
    let minutes: Int
    let ingredients: String
    let instructions: String
    static let all: [Recipe] = [
        Recipe(id: "salad", name: "Огуречный салат", emoji: "🥗", calories: 85, category: "Вегетарианские", meal: "Перекус", minutes: 5, ingredients: "Огурец 150 г, помидор 100 г, оливковое масло 5 г, зелень.", instructions: "Нарежьте овощи, добавьте зелень и заправьте маслом. Перемешайте перед подачей."),
        Recipe(id: "yogurt", name: "Йогурт с ягодами", emoji: "🫐", calories: 160, category: "Вегетарианские", meal: "Перекус", minutes: 5, ingredients: "Натуральный йогурт 150 г, ягоды 80 г, мёд 5 г.", instructions: "Промойте ягоды. Выложите на йогурт и добавьте мёд."),
        Recipe(id: "eggs", name: "Омлет со шпинатом", emoji: "🍳", calories: 260, category: "Вегетарианские", meal: "Завтрак", minutes: 12, ingredients: "2 яйца, молоко 30 мл, шпинат 50 г, масло 5 г, помидор 100 г.", instructions: "Взбейте яйца с молоком. Прогрейте шпинат в масле, залейте яйцами. Готовьте под крышкой до полной готовности, подайте с помидором."),
        Recipe(id: "oats", name: "Овсянка с бананом", emoji: "🥣", calories: 350, category: "Вегетарианские", meal: "Завтрак", minutes: 10, ingredients: "Овсяные хлопья 50 г, молоко 150 мл, банан 80 г, корица.", instructions: "Варите хлопья в молоке с небольшим количеством воды 5–7 минут. Добавьте нарезанный банан и корицу."),
        Recipe(id: "chicken", name: "Курица с гречкой", emoji: "🍗", calories: 450, category: "Обычные", meal: "Обед", minutes: 30, ingredients: "Куриное филе 150 г, сухая гречка 60 г, овощи 150 г, масло 5 г.", instructions: "Отварите гречку. Нарежьте филе и тушите с овощами и маслом до полной готовности курицы. Подавайте вместе."),
        Recipe(id: "salmon", name: "Лосось с рисом", emoji: "🐟", calories: 550, category: "Пескетарианские", meal: "Ужин", minutes: 30, ingredients: "Лосось 150 г, сухой рис 60 г, брокколи 150 г, лимон.", instructions: "Отварите рис. Запекайте лосось при 180 °C до готовности, ориентировочно 20 минут. Брокколи приготовьте на пару, сбрызните лимоном."),
        Recipe(id: "pasta", name: "Паста с тунцом", emoji: "🍝", calories: 650, category: "Пескетарианские", meal: "Обед", minutes: 20, ingredients: "Сухая паста 100 г, тунец в собственном соку 120 г, томаты 150 г, масло 10 г, пармезан 15 г.", instructions: "Отварите пасту. Прогрейте томаты с маслом, добавьте тунец. Смешайте с пастой и посыпьте сыром."),
        Recipe(id: "bowl", name: "Боул с авокадо", emoji: "🥑", calories: 760, category: "Вегетарианские", meal: "Ужин", minutes: 25, ingredients: "Сухая киноа 80 г, варёный нут 120 г, авокадо 100 г, овощи 150 г, тахини 15 г.", instructions: "Промойте и отварите киноа. Выложите в миску с нутом, нарезанным авокадо и овощами. Разведите тахини водой и полейте боул.")
    ]
}
struct RecipesView: View {
    @State private var search = ""
    @State private var category = "Все"
    @State private var meal = "Все"
    @State private var calorieIndex = -1
    @State private var favoritesOnly = false
    @AppStorage("sportlog.recipe.favorites") private var favorites = ""
    private let ranges = ["50–100", "100–200", "200–300", "300–400", "400–500", "500–600", "600–700", "700+"]
    private var filtered: [Recipe] {
        Recipe.all.filter { recipe in
            let lower = calorieIndex == 0 ? 50 : calorieIndex * 100
            let upper = calorieIndex == 7 ? Int.max : (calorieIndex + 1) * 100
            return (search.isEmpty || recipe.name.localizedCaseInsensitiveContains(search)) && (category == "Все" || recipe.category == category) && (meal == "Все" || recipe.meal == meal) && (calorieIndex == -1 || (recipe.calories >= lower && recipe.calories < upper)) && (!favoritesOnly || favorites.split(separator: ",").contains(Substring(recipe.id)))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Категории").font(.title3).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(["Все", "Обычные", "Вегетарианские", "Пескетарианские"], id: \.self) { item in
                        chip(item, selected: category == item) { category = item }
                    } }
                }
                VStack(alignment: .leading, spacing: 14) {
                    Text("Вкусно. Просто. В твоём ритме.").font(.title2.bold())
                    Text("8 рецептов для каждого дня").foregroundStyle(.secondary)
                    HStack { Text("🥗").font(.system(size: 55)); Spacer(); Text("🍳").font(.system(size: 55)); Spacer(); Text("🥑").font(.system(size: 55)) }
                }.logCard()
                Text("Приёмы пищи").font(.title3).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(["Все", "Завтрак", "Обед", "Ужин", "Перекус"], id: \.self) { item in chip(item, selected: meal == item) { meal = item } } } }
                Text("Калорийность на порцию").font(.title3).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 75))], spacing: 10) {
                    ForEach(ranges.indices, id: \.self) { index in
                        Button { calorieIndex = calorieIndex == index ? -1 : index } label: {
                            VStack(spacing: 6) { Text(ranges[index]).font(.subheadline.bold()); Text("ккал").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 20).background(calorieIndex == index ? LogStyle.coral.opacity(0.4) : LogStyle.card, in: RoundedRectangle(cornerRadius: 22))
                        }.buttonStyle(.plain)
                    }
                }
                HStack { Text("Рецепты · \(filtered.count)").font(.title2.bold()); Spacer(); Button("Сбросить") { category = "Все"; meal = "Все"; calorieIndex = -1; search = ""; favoritesOnly = false }.font(.caption) }
                if filtered.isEmpty { ContentUnavailableView.search(text: search) }
                ForEach(filtered) { recipe in
                    NavigationLink { RecipeDetail(recipe: recipe) } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            RecipePhoto(recipe: recipe).frame(height: 190).clipped().clipShape(RoundedRectangle(cornerRadius: 22))
                            Text(recipe.name).font(.title3.bold())
                            Text("≈\(recipe.calories) ккал · \(recipe.minutes) мин · \(recipe.meal)").font(.caption).foregroundStyle(.secondary)
                        }.logCard()
                    }.buttonStyle(.plain)
                }
                Text("Калорийность ориентировочная, на одну порцию: зависит от продуктов и способа приготовления.").font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.background(LogStyle.background).navigationTitle("Рецепты")
            .searchable(text: $search, prompt: "Что приготовим?")
            .toolbar { Button { favoritesOnly.toggle() } label: { Image(systemName: favoritesOnly ? "heart.fill" : "heart") }.accessibilityLabel("Только избранное") }
    }
    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(text).font(.subheadline).padding(.horizontal, 18).padding(.vertical, 16).background(selected ? LogStyle.coral.opacity(0.4) : LogStyle.card, in: Capsule()) }.buttonStyle(.plain)
    }
}
struct RecipePhoto: View {
    let recipe: Recipe
    var body: some View {
        if UIImage(named: recipe.id) != nil { Image(recipe.id).resizable().scaledToFill() }
        else { ZStack { LogStyle.card; Text(recipe.emoji).font(.system(size: 70)) } }
    }
}
struct RecipeDetail: View {
    let recipe: Recipe
    @AppStorage("sportlog.recipe.favorites") private var favorites = ""
    private var favorite: Bool { favorites.split(separator: ",").contains(Substring(recipe.id)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RecipePhoto(recipe: recipe).frame(height: 240).clipped().clipShape(RoundedRectangle(cornerRadius: 28))
                Text(recipe.name).font(.largeTitle.bold())
                Text("≈\(recipe.calories) ккал / порция · \(recipe.minutes) минут").foregroundStyle(LogStyle.coral)
                Text("Ингредиенты на 1 порцию").font(.title2.bold())
                Text(recipe.ingredients)
                Text("Как приготовить").font(.title2.bold())
                Text(recipe.instructions)
                Text("Фото иллюстративное. Калорийность — приблизительная оценка, уточняйте по упаковкам ингредиентов.").font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.background(LogStyle.background).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button {
                var ids = Set(favorites.split(separator: ",").map(String.init))
                if favorite { ids.remove(recipe.id) } else { ids.insert(recipe.id) }
                favorites = ids.sorted().joined(separator: ",")
            } label: { Image(systemName: favorite ? "heart.fill" : "heart") }.accessibilityLabel(favorite ? "Убрать из избранного" : "В избранное") }
    }
}
