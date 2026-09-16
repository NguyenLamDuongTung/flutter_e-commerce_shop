import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { HttpError } from '../utils/httpError.js';
import { mapProduct } from '../utils/productMapper.js';

const router = Router();

const productSelect = `
  SELECT
    p.id,
    p.category_id,
    c.name AS category_name,
    c.slug AS category_slug,
    p.name,
    p.slug,
    p.short_description,
    p.description,
    p.price,
    p.compare_price,
    p.stock_quantity,
    p.featured,
    p.is_active,
    p.specifications,
    p.created_at,
    p.updated_at,

    COALESCE(
      (
        SELECT JSON_ARRAYAGG(
          JSON_OBJECT(
            'id', image_data.id,
            'imageUrl', image_data.image_url,
            'altText', image_data.alt_text,
            'displayOrder', image_data.display_order,
            'isPrimary', image_data.is_primary
          )
        )
        FROM (
          SELECT
            pi.id,
            pi.image_url,
            pi.alt_text,
            pi.display_order,
            pi.is_primary
          FROM product_images pi
          WHERE pi.product_id = p.id
          ORDER BY pi.is_primary DESC, pi.display_order ASC
        ) AS image_data
      ),
      JSON_ARRAY()
    ) AS images

  FROM products p
  JOIN categories c ON c.id = p.category_id
`;

router.get('/categories', async (request, response, next) => {
  try {
    const [rows] = await database.execute(`
      SELECT
        c.id,
        c.name,
        c.slug,
        c.display_order,
        COUNT(p.id) AS product_count
      FROM categories c
      LEFT JOIN products p
        ON p.category_id = c.id
        AND p.is_active = TRUE
      WHERE c.is_active = TRUE
      GROUP BY
        c.id,
        c.name,
        c.slug,
        c.display_order
      ORDER BY c.display_order ASC, c.name ASC
    `);

    response.json({
      success: true,
      data: rows.map((row) => ({
        id: row.id,
        name: row.name,
        slug: row.slug,
        displayOrder: row.display_order,
        productCount: Number(row.product_count),
      })),
    });
  } catch (error) {
    next(error);
  }
});

router.get('/', async (request, response, next) => {
  try {
    const querySchema = z.object({
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(48).default(12),
      search: z.string().trim().max(100).optional().default(''),
      category: z.string().trim().max(120).optional(),
      featured: z
        .enum(['true', 'false'])
        .optional()
        .transform((value) =>
          value === undefined ? undefined : value === 'true',
        ),
      sort: z
        .enum([
          'newest',
          'price-asc',
          'price-desc',
          'name-asc',
        ])
        .default('newest'),
    });

    const query = querySchema.parse(request.query);
    const offset = (query.page - 1) * query.limit;

    const conditions = [
      'p.is_active = TRUE',
      'c.is_active = TRUE',
    ];

    const parameters = [];

    if (query.search) {
      conditions.push(`
        (
          p.name LIKE ?
          OR p.short_description LIKE ?
          OR c.name LIKE ?
        )
      `);

      const searchValue = `%${query.search}%`;

      parameters.push(
        searchValue,
        searchValue,
        searchValue,
      );
    }

    if (query.category) {
      conditions.push('c.slug = ?');
      parameters.push(query.category);
    }

    if (query.featured !== undefined) {
      conditions.push('p.featured = ?');
      parameters.push(query.featured);
    }

    const orderBy = {
      newest: 'p.created_at DESC',
      'price-asc': 'p.price ASC',
      'price-desc': 'p.price DESC',
      'name-asc': 'p.name ASC',
    }[query.sort];

    const whereSql = conditions.join(' AND ');

    const [countRows] = await database.execute(
      `
        SELECT COUNT(*) AS total
        FROM products p
        JOIN categories c ON c.id = p.category_id
        WHERE ${whereSql}
      `,
      parameters,
    );

    const [rows] = await database.execute(
      `
        ${productSelect}
        WHERE ${whereSql}
        ORDER BY ${orderBy}
        LIMIT ${Number(query.limit)}
        OFFSET ${Number(offset)}
      `,
      parameters,
    );

    const totalItems = Number(countRows[0].total);
    const totalPages = Math.ceil(totalItems / query.limit);

    response.json({
      success: true,
      data: {
        items: rows.map(mapProduct),
        pagination: {
          page: query.page,
          limit: query.limit,
          totalItems,
          totalPages,
          hasNextPage: query.page < totalPages,
          hasPreviousPage: query.page > 1,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/:slug', async (request, response, next) => {
  try {
    const [rows] = await database.execute(
      `
        ${productSelect}
        WHERE p.slug = ?
          AND p.is_active = TRUE
          AND c.is_active = TRUE
        LIMIT 1
      `,
      [request.params.slug],
    );

    if (rows.length === 0) {
      throw new HttpError(404, 'Product was not found.');
    }

    response.json({
      success: true,
      data: mapProduct(rows[0]),
    });
  } catch (error) {
    next(error);
  }
});

export default router;