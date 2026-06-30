CREATE TABLE "colors" (
	"id" bigint,
	"name" text,
	"rgb" text,
	"is_trans" text
);

CREATE TABLE "inventories" (
	"id" bigint,
	"version" bigint,
	"set_num" text
);

CREATE TABLE "inventory_sets" (
  "inventory_id" bigint,
  "set_num" text,
  "quantity" bigint
);

CREATE TABLE "part_categories" (
  "id" bigint,
  "name" text
);

CREATE TABLE "themes" (
  "id" bigint,
  "name" text,
  "parent_id" text NULL
);

CREATE TABLE "parts" (
  "part_num" text,
  "name" text,
  "part_cat_id" bigint
);

CREATE TABLE "sets" (
  "set_num" text,
  "name" text,
  "year" bigint,
  "theme_id" bigint,
  "num_parts" bigint
);

CREATE TABLE "inventory_parts" (
  "inventory_id" bigint,
  "part_num" text,
  "color_id" bigint,
  "quantity" bigint,
  "is_spare" text
);

ALTER TABLE sets ADD FOREIGN KEY (theme_id) REFERENCES themes(id);

ALTER TABLE inventories ADD PRIMARY KEY (id);

ALTER TABLE inventories ADD FOREIGN KEY (set_num) REFERENCES sets(set_num);

ALTER TABLE inventory_sets ADD FOREIGN KEY (inventory_id) REFERENCES inventories(id);

ALTER TABLE inventory_sets ADD FOREIGN KEY (set_num) REFERENCES sets(set_num);

ALTER TABLE part_categories ADD PRIMARY KEY (id);

ALTER TABLE parts ADD PRIMARY KEY (part_num);

ALTER TABLE parts ADD FOREIGN KEY (part_cat_id) REFERENCES part_categories(id);

ALTER TABLE colors ADD PRIMARY KEY (id);

ALTER TABLE inventory_parts ADD FOREIGN KEY (inventory_id) REFERENCES inventories(id);

--Some wrong connection leads to an incomplete reference
--ALTER TABLE inventory_parts ADD FOREIGN KEY (part_num) REFERENCES parts(part_num);

ALTER TABLE inventory_parts ADD FOREIGN KEY (color_id) REFERENCES colors(id);