import fs from 'node:fs/promises';
import path from 'node:path';

import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { env } from '../config/env.js';
import { authenticate } from '../middleware/authenticate.js';
import { authorizeAdmin } from '../middleware/authorizeAdmin.js';
import { uploadProductImages } from '../middleware/uploadProductImage.js';
import { HttpError } from '../utils/httpError.js';
import { mapProduct } from '../utils/productMapper.js';

const router = Router();

router.use(authenticate);
router.use(authorizeAdmin);

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

const productSchema = z.object({
  categoryId: z.coerce.number().int().positive(),
  name: z.string().trim().min(2).max(180),
  slug: z
    .string()
    .trim()
    .min(2)
    .max(200)
    .regex(
      /^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      'Slug must contain lowercase letters, numbers and hyphens only.',
    ),
  shortDescription: z.string().trim().max(500).optional().default(''),
  description: z.string().trim().optional().default(''),
  price: z.coerce.number().min(0),
  comparePrice: z.union([
    z.coerce.number().min(0),
    z.literal(''),
    z.null(),
  ]).optional(),
  stockQuantity: z.coerce.number().int().min(0),
  featured: z
    .union([z.boolean(), z.enum(['true', 'false', '1', '0'])])
    .transform((value) =>
      value === true || value === 'true' || value === '1'
    ),
  isActive: z
    .union([z.boolean(), z.enum(['true', 'false', '1', '0'])])
    .transform((value) =>
      value === true || value === 'true' || value === '1'
    ),
  specifications: z.string().optional().default('{}'),
});

function parseProductInput(body) {
  const input = productSchema.parse(body);

  let specifications;

  try {
    specifications = JSON.parse(input.specifications || '{}');
  } catch {
    throw new HttpError(
      400,
      'Specifications must be valid JSON.',
    );
  }

  if (
    specifications === null ||
    Array.isArray(specifications) ||
    typeof specifications !== 'object'
  ) {
    throw new HttpError(
      400,
      'Specifications must be a JSON object.',
    );
  }

  return {
    ...input,
    comparePrice:
      input.comparePrice === '' ||
      input.comparePrice === undefined
        ? null
        : input.comparePrice,
    specifications: JSON.stringify(specifications),
  };
}

async function getProduct(productId, connection = database) {
  const [rows] = await connection.execute(
    `
      ${productSelect}
      WHERE p.id = ?
      LIMIT 1
    `,
    [productId],
  );

  return rows[0] ? mapProduct(rows[0]) : null;
}

async function verifyCategory(categoryId, connection) {
  const [rows] = await connection.execute(
    `
      SELECT id
      FROM categories
      WHERE id = ? AND is_active = TRUE
      LIMIT 1
    `,
    [categoryId],
  );

  if (rows.length === 0) {
    throw new HttpError(400, 'Selected category is invalid.');
  }
}

router.get('/', async (request, response, next) => {
  try {
    const schema = z.object({
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(20),
      search: z.string().trim().max(100).optional().default(''),
      status: z
        .enum(['all', 'active', 'inactive'])
        .default('all'),
    });

    const query = schema.parse(request.query);
    const offset = (query.page - 1) * query.limit;

    const conditions = ['1 = 1'];
    const parameters = [];

    if (query.search) {
      conditions.push('(p.name LIKE ? OR p.slug LIKE ?)');

      const searchValue = `%${query.search}%`;
      parameters.push(searchValue, searchValue);
    }

    if (query.status === 'active') {
      conditions.push('p.is_active = TRUE');
    }

    if (query.status === 'inactive') {
      conditions.push('p.is_active = FALSE');
    }

    const whereSql = conditions.join(' AND ');

    const [countRows] = await database.execute(
      `
        SELECT COUNT(*) AS total
        FROM products p
        WHERE ${whereSql}
      `,
      parameters,
    );

    const [rows] = await database.execute(
      `
        ${productSelect}
        WHERE ${whereSql}
        ORDER BY p.updated_at DESC
        LIMIT ${Number(query.limit)}
        OFFSET ${Number(offset)}
      `,
      parameters,
    );

    const totalItems = Number(countRows[0].total);

    response.json({
      success: true,
      data: {
        items: rows.map(mapProduct),
        pagination: {
          page: query.page,
          limit: query.limit,
          totalItems,
          totalPages: Math.ceil(totalItems / query.limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (request, response, next) => {
  try {
    const productId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    const product = await getProduct(productId);

    if (!product) {
      throw new HttpError(404, 'Product was not found.');
    }

    response.json({
      success: true,
      data: product,
    });
  } catch (error) {
    next(error);
  }
});

router.post(
  '/',
  uploadProductImages,
  async (request, response, next) => {
    let connection;

    try {
      const input = parseProductInput(request.body);
      const files = request.files ?? [];

      connection = await database.getConnection();
      await connection.beginTransaction();

      await verifyCategory(input.categoryId, connection);

      const [result] = await connection.execute(
        `
          INSERT INTO products (
            category_id,
            name,
            slug,
            short_description,
            description,
            price,
            compare_price,
            stock_quantity,
            featured,
            is_active,
            specifications
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `,
        [
          input.categoryId,
          input.name,
          input.slug,
          input.shortDescription || null,
          input.description || null,
          input.price,
          input.comparePrice,
          input.stockQuantity,
          input.featured,
          input.isActive,
          input.specifications,
        ],
      );

      for (let index = 0; index < files.length; index += 1) {
        const file = files[index];

        await connection.execute(
          `
            INSERT INTO product_images (
              product_id,
              image_url,
              alt_text,
              display_order,
              is_primary
            )
            VALUES (?, ?, ?, ?, ?)
          `,
          [
            result.insertId,
            `/uploads/products/${file.filename}`,
            input.name,
            index,
            index === 0,
          ],
        );
      }

      await connection.commit();

      const product = await getProduct(result.insertId);

      response.status(201).json({
        success: true,
        message: 'Product created successfully.',
        data: product,
      });
    } catch (error) {
      if (connection) {
        await connection.rollback();
      }

      for (const file of request.files ?? []) {
        await fs.unlink(file.path).catch(() => {});
      }

      next(error);
    } finally {
      connection?.release();
    }
  },
);

router.put(
  '/:id',
  uploadProductImages,
  async (request, response, next) => {
    let connection;

    try {
      const productId = z.coerce
        .number()
        .int()
        .positive()
        .parse(request.params.id);

      const input = parseProductInput(request.body);
      const files = request.files ?? [];

      connection = await database.getConnection();
      await connection.beginTransaction();

      const [existingRows] = await connection.execute(
        'SELECT id FROM products WHERE id = ? LIMIT 1',
        [productId],
      );

      if (existingRows.length === 0) {
        throw new HttpError(404, 'Product was not found.');
      }

      await verifyCategory(input.categoryId, connection);

      await connection.execute(
        `
          UPDATE products
          SET
            category_id = ?,
            name = ?,
            slug = ?,
            short_description = ?,
            description = ?,
            price = ?,
            compare_price = ?,
            stock_quantity = ?,
            featured = ?,
            is_active = ?,
            specifications = ?
          WHERE id = ?
        `,
        [
          input.categoryId,
          input.name,
          input.slug,
          input.shortDescription || null,
          input.description || null,
          input.price,
          input.comparePrice,
          input.stockQuantity,
          input.featured,
          input.isActive,
          input.specifications,
          productId,
        ],
      );

      const [orderRows] = await connection.execute(
        `
          SELECT COALESCE(MAX(display_order), -1) AS maximum
          FROM product_images
          WHERE product_id = ?
        `,
        [productId],
      );

      const startingOrder =
        Number(orderRows[0].maximum) + 1;

      for (let index = 0; index < files.length; index += 1) {
        const file = files[index];

        const [primaryRows] = await connection.execute(
          `
            SELECT id
            FROM product_images
            WHERE product_id = ? AND is_primary = TRUE
            LIMIT 1
          `,
          [productId],
        );

        await connection.execute(
          `
            INSERT INTO product_images (
              product_id,
              image_url,
              alt_text,
              display_order,
              is_primary
            )
            VALUES (?, ?, ?, ?, ?)
          `,
          [
            productId,
            `/uploads/products/${file.filename}`,
            input.name,
            startingOrder + index,
            primaryRows.length === 0 && index === 0,
          ],
        );
      }

      await connection.commit();

      response.json({
        success: true,
        message: 'Product updated successfully.',
        data: await getProduct(productId),
      });
    } catch (error) {
      if (connection) {
        await connection.rollback();
      }

      for (const file of request.files ?? []) {
        await fs.unlink(file.path).catch(() => {});
      }

      next(error);
    } finally {
      connection?.release();
    }
  },
);

router.patch('/:id/status', async (request, response, next) => {
  try {
    const productId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    const input = z
      .object({
        isActive: z.boolean(),
      })
      .parse(request.body);

    const [result] = await database.execute(
      `
        UPDATE products
        SET is_active = ?
        WHERE id = ?
      `,
      [input.isActive, productId],
    );

    if (result.affectedRows === 0) {
      throw new HttpError(404, 'Product was not found.');
    }

    response.json({
      success: true,
      message: input.isActive
        ? 'Product activated successfully.'
        : 'Product hidden successfully.',
      data: await getProduct(productId),
    });
  } catch (error) {
    next(error);
  }
});

router.patch(
  '/:productId/images/:imageId/primary',
  async (request, response, next) => {
    let connection;

    try {
      const parameters = z
        .object({
          productId: z.coerce.number().int().positive(),
          imageId: z.coerce.number().int().positive(),
        })
        .parse(request.params);

      connection = await database.getConnection();
      await connection.beginTransaction();

      const [imageRows] = await connection.execute(
        `
          SELECT id
          FROM product_images
          WHERE id = ? AND product_id = ?
          LIMIT 1
        `,
        [parameters.imageId, parameters.productId],
      );

      if (imageRows.length === 0) {
        throw new HttpError(404, 'Product image was not found.');
      }

      await connection.execute(
        `
          UPDATE product_images
          SET is_primary = FALSE
          WHERE product_id = ?
        `,
        [parameters.productId],
      );

      await connection.execute(
        `
          UPDATE product_images
          SET is_primary = TRUE
          WHERE id = ?
        `,
        [parameters.imageId],
      );

      await connection.commit();

      response.json({
        success: true,
        message: 'Primary image updated successfully.',
        data: await getProduct(parameters.productId),
      });
    } catch (error) {
      if (connection) {
        await connection.rollback();
      }

      next(error);
    } finally {
      connection?.release();
    }
  },
);

router.delete(
  '/:productId/images/:imageId',
  async (request, response, next) => {
    let connection;

    try {
      const parameters = z
        .object({
          productId: z.coerce.number().int().positive(),
          imageId: z.coerce.number().int().positive(),
        })
        .parse(request.params);

      connection = await database.getConnection();
      await connection.beginTransaction();

      const [rows] = await connection.execute(
        `
          SELECT id, image_url, is_primary
          FROM product_images
          WHERE id = ? AND product_id = ?
          LIMIT 1
        `,
        [parameters.imageId, parameters.productId],
      );

      const image = rows[0];

      if (!image) {
        throw new HttpError(404, 'Product image was not found.');
      }

      await connection.execute(
        'DELETE FROM product_images WHERE id = ?',
        [parameters.imageId],
      );

      if (image.is_primary) {
        const [remainingImages] = await connection.execute(
          `
            SELECT id
            FROM product_images
            WHERE product_id = ?
            ORDER BY display_order ASC
            LIMIT 1
          `,
          [parameters.productId],
        );

        if (remainingImages.length > 0) {
          await connection.execute(
            `
              UPDATE product_images
              SET is_primary = TRUE
              WHERE id = ?
            `,
            [remainingImages[0].id],
          );
        }
      }

      await connection.commit();

      if (image.image_url.startsWith('/uploads/')) {
        const relativePath = image.image_url.replace(
          /^\/uploads\//,
          '',
        );

        const filePath = path.resolve(
          process.cwd(),
          'uploads',
          relativePath,
        );

        await fs.unlink(filePath).catch(() => {});
      }

      response.json({
        success: true,
        message: 'Product image removed successfully.',
        data: await getProduct(parameters.productId),
      });
    } catch (error) {
      if (connection) {
        await connection.rollback();
      }

      next(error);
    } finally {
      connection?.release();
    }
  },
);

router.delete('/:id', async (request, response, next) => {
  try {
    const productId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    const [result] = await database.execute(
      `
        UPDATE products
        SET is_active = FALSE
        WHERE id = ?
      `,
      [productId],
    );

    if (result.affectedRows === 0) {
      throw new HttpError(404, 'Product was not found.');
    }

    response.json({
      success: true,
      message: 'Product removed from the store successfully.',
    });
  } catch (error) {
    next(error);
  }
});

export default router;