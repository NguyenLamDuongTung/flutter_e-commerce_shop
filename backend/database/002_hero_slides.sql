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
  KEY idx_hero_slides_active_order (is_active, display_order),

  CONSTRAINT fk_hero_slides_product
    FOREIGN KEY (product_id)
    REFERENCES products(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;