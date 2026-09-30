USE flutter_shop_db;

CREATE TABLE IF NOT EXISTS hero_slides (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  subtitle VARCHAR(500) NULL,
  button_text VARCHAR(80) NOT NULL DEFAULT 'Khám phá ngay',
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),

  UNIQUE KEY uq_hero_slides_product (product_id),

  KEY idx_hero_slides_active_order (
    is_active,
    display_order
  ),

  CONSTRAINT fk_hero_slides_product
    FOREIGN KEY (product_id)
    REFERENCES products(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO hero_slides (
  product_id,
  title,
  subtitle,
  button_text,
  display_order,
  is_active
)
SELECT
  p.id,
  p.name,
  COALESCE(
    p.short_description,
    'Khám phá sản phẩm công nghệ mới nhất.'
  ),
  'Khám phá ngay',
  CASE p.slug
    WHEN 'nova-phone-pro' THEN 1
    WHEN 'novapad-pro' THEN 2
    WHEN 'novabook-air' THEN 3
    ELSE 99
  END,
  TRUE
FROM products p
WHERE p.slug IN (
  'nova-phone-pro',
  'novapad-pro',
  'novabook-air'
)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  subtitle = VALUES(subtitle),
  button_text = VALUES(button_text),
  display_order = VALUES(display_order),
  is_active = TRUE;