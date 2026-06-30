SELECT
	sets.set_num AS "Set Number",
	sets.name AS "Set Name",
	parts.part_num AS "Part Number",
	parts.name AS "Part Name",
	ip.quantity AS "Part Quantity",
	pc.name AS "Part Category",
	colors.name AS "Color Name",
	colors.rgb AS "Color RGB"
FROM sets
LEFT JOIN themes AS t ON sets.theme_id = t.id
LEFT JOIN inventories AS inv ON sets.set_num = inv.set_num
LEFT JOIN inventory_parts AS ip ON inv.id = ip.inventory_id
LEFT JOIN colors ON ip.color_id = colors.id
LEFT JOIN parts ON ip.part_num = parts.part_num
LEFT JOIN part_categories AS pc ON parts.part_cat_id = pc.id
WHERE ip.is_spare = 'f' AND t."name" LIKE '%Star Wars%';