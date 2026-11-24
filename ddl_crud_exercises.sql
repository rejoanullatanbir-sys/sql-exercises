
-- 1. Design a reviews table
create table reviews (
    user_id    int not null references users(id),      
    product_id int not null references products(id),   
    rating     int not null check (rating between 1 and 5),  
    comment    text,                                     
    created_at timestamptz not null default now(),       
    primary key (user_id, product_id)
);

-- 2. Add a column
alter table users add column phone_number text;

-- 3. Add a constraint after the fact
alter table orders
add constraint orders_quantity_max_10 check (quantity <= 10);

-- 4. Insert a product
insert into products (name, category, price, stock)
values ('Studio Desk Lamp', 'Office', 45.50, 25)
returning id;

-- 5. A catalog-wide price increase
select id, name, price from products where category = 'Furniture';
update products
set price = price * 1.10
where category = 'Furniture';
select id, name, price from products where category = 'Furniture';
-- 6. Auto-cancel stale orders
select count(*) from orders
where status = 'pending'
  and created_at < now() - interval '30 days';

update orders
set status = 'cancelled'
where status = 'pending'
  and created_at < now() - interval '30 days';
select count(*) from orders
where status = 'pending'
  and created_at < now() - interval '30 days';
-- 7. Delete, and explain the failure
select product_id, count(*) as order_count
from orders
where product_id = 1
group by product_id;
delete from products where id = 1;

-- Error message:
-- SQL Error [23503]: ERROR: update or delete on table "products" violates foreign key
-- constraint "orders_product_id_fkey" on table "orders"
-- Detail: Key (id)=(1) is still referenced from table "orders".

-- Why: Postgres stops the delete because of referential integrity: orders still
-- use product 1 through a foreign key, and deleting it would leave those orders
-- pointing to a product that no longer exists.

-- 8. Indexing a new query pattern
create index idx_orders_status_created_at
on orders (status, created_at);
explain select * from orders where status = 'pending' order by created_at;
-- 9. A safe restock-and-order transaction
select id, stock from products where id = 1;
begin;
insert into orders (user_id, product_id, quantity, status)
values (1, 1, 2, 'pending');

update products
set stock = stock - 2
where id = 1;
commit;
select id, stock from products where id = 1;
select * from orders where user_id = 1 order by id desc limit 1;


