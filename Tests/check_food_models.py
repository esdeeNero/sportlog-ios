"""Run nutrition model checks against the actual app source: python3 Tests/check_food_models.py."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "SportLog/FoodDiary.swift").read_text()
models = source[source.index("nonisolated struct FoodPortion"):source.index("nonisolated struct FoodSuggestion")]
checks = 'var food = FoodPortion(name: "Test", grams: 250, kcal100: 120, protein100: 10, fat100: 4, carbs100: 11)\nassert(food.valid)\nassert(food.calories == 300 && food.protein == 25 && food.fat == 10 && food.carbs == 27.5)\nfood.grams = 50\nassert(food.calories == 60 && food.protein == 5)\nvar second = food; second.id = UUID()\nlet entry = FoodEntry(meal: "Обед", portions: [food, second])\nassert(entry.calories == 120)\nlet decoded = try JSONDecoder().decode(FoodEntry.self, from: JSONEncoder().encode(entry))\nassert(decoded.id == entry.id && decoded.portions[0].id == food.id && decoded.calories == 120)\nfood.grams = -1; assert(!food.valid)\nfood.grams = .infinity; assert(!food.valid)\nfood.grams = 100; food.protein100 = .nan; assert(!food.valid)\nfood.protein100 = 5; food.name = "  "; assert(!food.valid)\nassert(Set(FoodTemplate.all.map(\\.id)).count == FoodTemplate.all.count)\nassert(FoodTemplate.all.allSatisfy { $0.portion.valid })\nprint("PASS: portion scaling, totals, persistence, validation, catalog IDs")\n'
with tempfile.TemporaryDirectory(prefix="sportlog-food-check-") as directory:
    script = Path(directory) / "checks.swift"
    script.write_text("import Foundation\n" + models + checks)
    subprocess.run(["xcrun", "swift", str(script)], check=True)
