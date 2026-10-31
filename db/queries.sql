-- queries.sql: SQL-запросы для приложения (магазин обуви, MySQL 8)
-- Знак ? - параметр: в C# сюда подставляется значение из формы (через параметры команды).
-- Чтобы проверить запрос в Workbench, замените ? на значение (готовые примеры - в строках "-- Проверка:").
-- В скобках указаны пункты чек-листа ДЭ.

USE `shoestore`;

-- =====================================================================
-- 1. Вход в приложение (пункты 2.5, 2.6, 3.17)
--    Пустой результат = неправильный логин или пароль; иначе - ФИО и роль.
-- =====================================================================
SELECT u.id, u.full_name, r.name AS role
FROM users u
JOIN roles r ON r.id = u.role_id
WHERE u.login = ? AND u.password = ?;
-- Проверка: WHERE u.login = '94d5ous@gmail.com' AND u.password = 'uzWC67'  -> 1 строка (Никифорова Весения Николаевна, Администратор)

-- =====================================================================
-- 2. Каталог товаров: окна Гостя и Администратора (пункты 2.7-2.11)
--    JOIN подставляет названия вместо category_id / manufacturer_id / supplier_id.
-- =====================================================================
SELECT p.id, p.article, p.name, p.unit, p.price, p.discount, p.stock_qty,
       p.description, p.photo,
       c.name AS category, m.name AS manufacturer, s.name AS supplier
FROM products p
JOIN categories c    ON c.id = p.category_id
JOIN manufacturers m ON m.id = p.manufacturer_id
JOIN suppliers s     ON s.id = p.supplier_id;
-- Проверка: возвращает 30 строк

-- =====================================================================
-- 3. Поиск, фильтр по поставщику и сортировка по остатку (пункты 3.2-3.6)
--    Один и тот же запрос с разным набором условий в WHERE.
-- =====================================================================
-- 3.1 Всё вместе: поиск по названию + фильтр по поставщику + сортировка
SELECT p.id, p.article, p.name, p.price, p.stock_qty, s.name AS supplier
FROM products p
JOIN suppliers s ON s.id = p.supplier_id
WHERE p.name LIKE CONCAT('%', ?, '%') AND p.supplier_id = ?
ORDER BY p.stock_qty DESC;
-- Проверка: LIKE '%Туфли%' AND p.supplier_id = 1 -> 6 строк, по убыванию остатка

-- 3.2 Только поиск
SELECT p.id, p.article, p.name, p.price, p.stock_qty, s.name AS supplier
FROM products p
JOIN suppliers s ON s.id = p.supplier_id
WHERE p.name LIKE CONCAT('%', ?, '%');

-- 3.3 Только фильтр по поставщику
SELECT p.id, p.article, p.name, p.price, p.stock_qty, s.name AS supplier
FROM products p
JOIN suppliers s ON s.id = p.supplier_id
WHERE p.supplier_id = ?;

-- 3.4 Только сортировка по остатку на складе (по возрастанию: ASC, по убыванию: DESC)
SELECT p.id, p.article, p.name, p.price, p.stock_qty, s.name AS supplier
FROM products p
JOIN suppliers s ON s.id = p.supplier_id
ORDER BY p.stock_qty ASC;

-- =====================================================================
-- 4. Добавление и редактирование товара (пункты 3.7, 3.10, 3.12, 3.19)
-- =====================================================================
-- справочники для выпадающих списков в форме
SELECT id, name FROM categories;
SELECT id, name FROM manufacturers;
SELECT id, name FROM suppliers;

-- добавление товара
INSERT INTO products
  (article, name, unit, price, discount, stock_qty, description, photo, category_id, manufacturer_id, supplier_id)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- открыть товар для редактирования - заполнить все поля сразу
SELECT * FROM products WHERE id = ?;

-- сохранить изменения
UPDATE products
SET article=?, name=?, unit=?, price=?, discount=?, stock_qty=?, description=?, photo=?,
    category_id=?, manufacturer_id=?, supplier_id=?
WHERE id = ?;

-- =====================================================================
-- 5. Защита от удаления купленного товара (пункт 3.16)
--    Сначала проверяем, есть ли товар в заказах - и показываем понятное предупреждение.
-- =====================================================================
SELECT COUNT(*) AS used_in_orders FROM prodorders WHERE product_id = ?;
-- Проверка: product_id = 1 -> 2 (товар есть в заказах 1 и 5)

-- Если used_in_orders = 0 - товар можно удалить:
DELETE FROM products WHERE id = ?;
-- Проверка: DELETE FROM products WHERE id = 1;
-- -> Error Code: 1451. Cannot delete or update a parent row: a foreign key constraint fails
--    (база сама не даст удалить купленный товар, т.к. у связи prodorders -> products нет CASCADE)
