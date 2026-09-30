import { Router } from 'express';

import { database } from '../config/database.js';

const router = Router();

router.get('/', async (request, response, next) => {
  try {
    const [rows] = await database.execute(`
      SELECT
        hs.id,
        hs.product_id,
        hs.title,
        hs.subtitle,
        hs.button_text,
        hs.display_order,

        p.slug AS product_slug,
        p.name AS product_name,

        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          ORDER BY
            pi.is_primary DESC,
            pi.display_order ASC
          LIMIT 1
        ) AS image_url

      FROM hero_slides hs

      JOIN products p
        ON p.id = hs.product_id

      WHERE hs.is_active = TRUE
        AND p.is_active = TRUE

      ORDER BY
        hs.display_order ASC,
        hs.id ASC
    `);

    response.json({
      success: true,

      data: rows.map((row) => ({
        id: row.id,

        productId: row.product_id,
        productSlug: row.product_slug,
        productName: row.product_name,

        title: row.title,
        subtitle: row.subtitle ?? '',
        buttonText: row.button_text,

        imageUrl: row.image_url,

        displayOrder: Number(row.display_order),

        isActive: true,
      })),
    });
  } catch (error) {
    next(error);
  }
});

export default router;