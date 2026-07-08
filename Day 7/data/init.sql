CREATE SCHEMA staging;

SET search_path TO staging;

CREATE TABLE "colors" (
	"id" bigint,
	"name" text,
	"rgb" text,
	"is_trans" boolean
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
  "is_spare" boolean
);

CREATE TABLE "themes" (
	"id" bigint,
	"name" text,
	"parent_id" bigint NULL
);

CREATE TABLE "elements" (
	"element_id" text,
	"part_num" text,
	"color_id" bigint
);

CREATE TABLE "part_relationships" (
	"rel_type" text,
	"child_part_num" text,
	"parent_part_num" text
);

CREATE TABLE "inventory_minifigs" (
	"inventory_id" bigint,
	"fig_num" text,
	"quantity" bigint
);

CREATE TABLE "minifigs" (
	"fig_num" text,
	"name" text,
	"num_parts" bigint
);

ALTER TABLE themes ADD PRIMARY KEY (id);

ALTER TABLE sets ADD PRIMARY KEY (set_num);

ALTER TABLE elements ADD PRIMARY KEY (element_id);

ALTER TABLE minifigs ADD PRIMARY KEY (fig_num);

ALTER TABLE inventories ADD PRIMARY KEY (id);

ALTER TABLE part_categories ADD PRIMARY KEY (id);

ALTER TABLE parts ADD PRIMARY KEY (part_num);

ALTER TABLE colors ADD PRIMARY KEY (id);

ALTER TABLE inventories ADD FOREIGN KEY (set_num) REFERENCES sets(set_num);

ALTER TABLE inventory_sets ADD FOREIGN KEY (inventory_id) REFERENCES inventories(id);

ALTER TABLE inventory_sets ADD FOREIGN KEY (set_num) REFERENCES sets(set_num);

ALTER TABLE inventory_parts ADD FOREIGN KEY (inventory_id) REFERENCES inventories(id);

ALTER TABLE inventory_parts ADD FOREIGN KEY (part_num) REFERENCES parts(part_num);

ALTER TABLE inventory_parts ADD FOREIGN KEY (color_id) REFERENCES colors(id);

ALTER TABLE parts ADD FOREIGN KEY (part_cat_id) REFERENCES part_categories(id);

ALTER TABLE sets ADD FOREIGN KEY (theme_id) REFERENCES themes(id);

ALTER TABLE elements ADD FOREIGN KEY (part_num) REFERENCES parts(part_num);

ALTER TABLE elements ADD FOREIGN KEY (color_id) REFERENCES colors(id);

ALTER TABLE part_relationships ADD FOREIGN KEY (child_part_num) REFERENCES parts(part_num);

ALTER TABLE part_relationships ADD FOREIGN KEY (parent_part_num) REFERENCES parts(part_num);

ALTER TABLE themes ADD FOREIGN KEY (parent_id) REFERENCES themes(id);

ALTER TABLE inventory_minifigs ADD FOREIGN KEY (inventory_id) REFERENCES inventories(id);

ALTER TABLE inventory_minifigs ADD FOREIGN KEY (fig_num) REFERENCES minifigs(fig_num);