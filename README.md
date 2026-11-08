# goit-rdb-fp

Фінальний проєкт курсу Relational Databases for DS: імпорт датасету `infectious_cases` у PostgreSQL, нормалізація до 3НФ, аналіз `Number_rabies`, колонка різниці в роках і дві власні SQL-функції.

## Вміст репозиторію

| Файл / папка | Опис |
|---|---|
| `fp_infectious_cases.ipynb` | Notebook з усіма запитами та збереженими output-ами клітинок |
| `final_project.sql` | Той самий SQL одним файлом (імпорт CSV у `psql` через `\copy`) |
| `data/infectious_cases.csv` | Датасет із завдання (10 521 рядок, 245 країн і регіонів, 1920–2023) |
| `screenshots/` | 13 скриншотів: схема, імпорт, структура таблиць, запити та результати |

## Виконання

1. **Завантаження даних.** `CREATE SCHEMA IF NOT EXISTS pandemic; SET search_path TO pandemic;`. CSV імпортується у таблицю `infectious_cases` через `COPY ... FROM STDIN (FORMAT csv, HEADER true)`. Усі колонки вихідної таблиці мають тип `TEXT`, порожні поля CSV потрапляють як `NULL`.
2. **Нормалізація до 3НФ.** `Code` залежить лише від `Entity`, тому пара винесена в окрему таблицю:
   - `entities (id PK, entity UNIQUE, code)`: 245 рядків; для агрегатів без коду (`Africa`, `Americas` та інші) `code = NULL`.
   - `cases (id PK, entity_id FK -> entities.id, year, 9 показників NUMERIC, UNIQUE (entity_id, year))`: 10 521 рядок.
   - Перевірка без втрат: `EXCEPT` між вихідною таблицею і результатом `JOIN` повертає 0 рядків в обидва боки.
3. **Аналіз.** Для кожної пари `Entity` + `Code` (за `entities.id`) рахуються `AVG`, `MIN`, `MAX`, `SUM` для `Number_rabies`, сортування за середнім за спаданням, `LIMIT 10`. Рядки з `NULL` не враховуються, щоб країни без даних не опинилися нагорі списку. У топі разом із країнами (наприклад, India) є агрегати датасету: `World`, `G20`, регіони WHO і Світового банку.
4. **Різниця в роках.** `make_date(year, 1, 1)`, `CURRENT_DATE` і `DATE_PART('year', AGE(CURRENT_DATE, make_date(year, 1, 1)))`.
5. **Власні функції.**
   - `year_diff(p_year INTEGER) RETURNS INTEGER`: різниця в повних роках між поточною датою та `YYYY-01-01`. Notebook перевіряє, що вона збігається з запитом із завдання 4 для всіх 10 521 рядків.
   - `avg_cases_per_period(cases_per_year NUMERIC, divisor NUMERIC) RETURNS NUMERIC`: середня кількість захворювань за період. Дільник `0` або `NULL` дає `NULL`, а не помилку. Перевірено на `12` (місяць), `4` (квартал) і `2` (півріччя). У запиті використані тільки записи з числовим `Number_rabies` (фільтр регулярним виразом на вихідній текстовій таблиці).

Результат завдання 4 і `year_diff` залежить від поточної дати, тому цифри `year_diff` у збережених output-ах відповідають даті запуску (2026-11-08).

## Запуск

1. Відкрити `fp_infectious_cases.ipynb` у Google Colab або локально (Python 3.12).
2. Runtime → Restart session and run all.

Перша клітинка встановлює залежності й запускає PostgreSQL через `pgserver`. Якщо `pgserver` недоступний (наприклад, у Colab з Python 3.13), notebook автоматично встановлює PostgreSQL через `apt`. CSV береться з `data/`; якщо файлу поруч немає, завантажується з GitHub. Повний прогін займає кілька секунд.

Для `psql` без notebook: створити базу, виконати `final_project.sql`, а команду імпорту `\copy` запустити з кореня репозиторію.
