---
name: tree-sitter-bsl-grammar
description: >-
  Grammar authoring for tree-sitter-bsl: grammar.js structure, adding BSL constructs,
  corpus test format, build/generate workflow, Python bindings, and version bumping.
  Use when editing grammar.js, adding corpus tests, debugging parse trees, or releasing
  a new grammar version.
---

# tree-sitter-bsl: грамматика и рабочий процесс

## Роль проекта

**tree-sitter-bsl** — [tree-sitter](https://tree-sitter.github.io/) грамматика для **1C:Enterprise BSL** (рус./англ. ключевые слова, case-insensitive). Грамматика определяется в `grammar.js`; `src/parser.c` **генерируется автоматически** и вручную не редактируется.

## Ключевые файлы

| Область | Файл | Роль |
|---------|------|------|
| **Грамматика** | `grammar.js` | Единственный файл для редактирования конструкций BSL |
| **Генерированный парсер** | `src/parser.c` | Генерируется `tree-sitter generate`, коммитится вместе с grammar.js |
| **Конфиг** | `tree-sitter.json` | Имя (`bsl`), расширения (`bsl`, `osl`), enabled bindings |
| **Python binding** | `bindings/python/tree_sitter_bsl/` | `Language()` функция, `_binding` extension |
| **Node binding** | `bindings/node/` | N-API addon |
| **Rust binding** | `bindings/rust/` | `LanguageFn` |
| **Corpus тесты** | `test/corpus/*.bsl` | Эталонные S-expression деревья |

## Структура `grammar.js`

```js
module.exports = grammar({
  name: 'bsl',
  conflicts: ($) => [[$.parenthesized_expression, $.arguments]],  // объявленный конфликт
  extras: ($) => [/\s/, $.line_comment],
  reserved: { global: ($) => reservedKeywords($) },  // ключевые слова ≠ identifier
  rules: { source_file: ($) => ..., ... }
})
```

**Ключевые секции:**
- `PREC` — числовые приоритеты выражений (`LOGICAL_OR` … `ASSIGNMENT`, `AWAIT`)
- `CORE_KEYWORDS` — пары `[русский, английский]`; `buildKeywords()` создаёт правила `IF_KEYWORD`, `WHILE_KEYWORD` и т.д.
- `PREPROC_KEYWORDS` — препроцессор: `#Если`/`#if`, `#Область`, аннотации `&НаКлиенте`, `&Перед(...)`
- Ключевые слова в `reservedKeywords` не могут быть `identifier` на верхнем уровне

## Добавление новой конструкции BSL

1. **Новые ключевые слова** → добавить в `CORE_KEYWORDS` или `PREPROC_KEYWORDS` (или как литерал в правиле)
2. **Новое правило** → добавить в `rules` через `seq`, `choice`, `repeat`, `optional`, `field`, `alias`, `prec`
3. **Зарезервированность** → если токен не должен быть identifier, убедиться что он попадает в `reservedKeywords` через `buildKeywords`
4. **Regenerate:** `tree-sitter generate` — обновляет `src/parser.c` и `src/*.json`
5. **Corpus тест** → добавить / обновить `test/corpus/*.bsl`
6. **Запустить:** `tree-sitter test`

```
❌ НИКОГДА не редактировать src/parser.c вручную
✅ Всегда: grammar.js → tree-sitter generate → tree-sitter test → commit оба файла
```

## Формат corpus-тестов

Файлы в `test/corpus/*.bsl`:

```
================
Имя теста (человекочитаемое)
================
// BSL-исходник
Процедура Тест()
    А = 1;
КонецПроцедуры
---

(source_file
  (procedure_definition
    name: (identifier)
    (statement_block
      (assignment
        left: (identifier)
        right: (number)))))
```

- Разделитель теста: строка из `=`
- Источник и S-expression разделены `---`
- Ошибочные/неполные деревья: `(MISSING ")")` в expected tree
- **Запуск:** `tree-sitter test`

Существующие corpus-файлы: `assignment.bsl`, `expressions.bsl`, `access.bsl`, `methods.bsl`, `execute.bsl`, `incomplete-expressions.bsl`.

**Nota bene:** правила для `goto`/`~label` в grammar.js есть, но corpus-тестов под них нет — хорошая область для добавления.

## Поддерживаемые конструкции BSL

**Топ-уровень:** процедуры, функции, `Перем`/`Var`, любые операторы.

**Операторы:** `Если`/`If`, `Пока`/`While`, `Для`/`For` (числовой и `Для Каждого`/`For Each`), `Попытка`/`Try`…`Исключение`/`Except`, `Возврат`/`Return`, `ВызватьИсключение`/`Raise`, **`Перейти`/`Goto` + `~метка:`**, `Прервать`/`Break`, `Продолжить`/`Continue`, `Ждать`/`Await`, `ДобавитьОбработчик`/`УдалитьОбработчик`, `Выполнить`/`Execute`, присваивание, вызов.

**Выражения:** числа, даты `'\d{8,14}'`, строки (`""`, `|`-продолжение), `Истина`/`Ложь`, `Неопределено`/`Null`, унарные, бинарные, сравнения, `?( cond, a, b )`, `Новый`/`New`, вызовы методов, `.` доступ к свойствам, `[ ]` индекс.

## Команды сборки и тестирования

| Что | Команда |
|-----|---------|
| Регенерировать парсер | `tree-sitter generate` |
| Corpus-тесты | `tree-sitter test` |
| Node binding тесты | `npm test` |
| Python binding тест | `python -m unittest bindings/python/tests/test_binding.py` |
| Lint grammar.js | `npm run lint` |
| Playground (WASM) | `npm start` (после `tree-sitter build --wasm`) |

## Python bindings: как использовать

```python
import tree_sitter_bsl
import tree_sitter

parser = tree_sitter.Parser(tree_sitter_bsl.Language())
tree = parser.parse(b"// BSL source")
```

- **`tree_sitter_bsl.Language()`** — публичный хелпер; внутри вызывает `_binding.language()` (C extension)
- Устанавливается через `pip install tree-sitter-bsl` или `pip install -e .` из репозитория
- В codemask-1c подключается как `file:///` зависимость через PDM/pipx

## Версии и бамп

- Версия в `pyproject.toml` и `package.json` — источник истины для релизов
- `tree-sitter.json` и `Cargo.toml` могут отставать — синхронизировать при публикации
- Текущая версия: **0.1.7**
- После grammar.js изменений обновлять `src/parser.c` (результат `tree-sitter generate`) и коммитить вместе
