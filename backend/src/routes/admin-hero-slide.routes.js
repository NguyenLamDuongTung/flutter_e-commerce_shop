import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { authenticate } from '../middleware/authenticate.js';
import { authorizeAdmin } from '../middleware/authorizeAdmin.js';
import { HttpError } from '../utils/httpError.js';

const router = Router();

router.use(authenticate);
router.use(authorizeAdmin);

const slideSchema = z.object({
  productId: z.coerce.number().int().positive(),
  title: z.string().trim().min(2).max(180),
  subtitle: z.string().trim().max(500).optional().default(''),
  buttonText: z
    .string()
    .trim()
    .min(1)
    .max(80)
    .default('Khám phá ngay'),
  displayOrder: z.coerce.number().int().min(0).default(0),
  isActive: z.boolean().default(true),
});

const selectSlides = `
  SELECT
    hs.id,
    hs.product_id,
    hs.title,
    hs.subtitle,
    hs.button_text,
    hs.display_order,
    hs.is_active,
    p.name AS product_name,
    p.slug AS product_slug,
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
  JOIN products p ON p.id = hs.product_id
`;

function mapSlide(row) {
  return {
    id: Number(row.id),
    productId: Number(row.product_id),
    productName: row.product_name,
    productSlug: row.product_slug,
    title: row.title,
    subtitle: row.subtitle ?? '',
    buttonText: row.button_text,
    imageUrl: row.image_url,
    displayOrder: Number(row.display_order),
    isActive: Boolean(row.is_active),
  };
}

async function findSlide(id) {
  const [rows] = await database.execute(
    `
      ${selectSlides}
      WHERE hs.id = ?
      LIMIT 1
    `,
    [id],
  );

  return rows.length > 0 ? mapSlide(rows[0]) : null;
}

async function checkProduct(productId) {
  const [rows] = await database.execute(
    `
      SELECT id
      FROM products
      WHERE id = ?
      LIMIT 1
    `,
    [productId],
  );

  if (rows.length === 0) {
    throw new HttpError(
      400,
      'Selected product does not exist.',
    );
  }
}

router.get('/', async (request, response, next) => {
  try {
    const [rows] = await database.execute(
      `
        ${selectSlides}
        ORDER BY
          hs.display_order ASC,
          hs.id ASC
      `,
    );

    response.json({
      success: true,
      data: rows.map(mapSlide),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (request, response, next) => {
  try {
    const input = slideSchema.parse(request.body);

    await checkProduct(input.productId);

    const [result] = await database.execute(
      `
        INSERT INTO hero_slides (
          product_id,
          title,
          subtitle,
          button_text,
          display_order,
          is_active
        )
        VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        input.productId,
        input.title,
        input.subtitle || null,
        input.buttonText,
        input.displayOrder,
        input.isActive,
      ],
    );

    response.status(201).json({
      success: true,
      message: 'Hero slide created successfully.',
      data: await findSlide(result.insertId),
    });
  } catch (error) {
    if (error?.code === 'ER_DUP_ENTRY') {
      next(
        new HttpError(
          409,
          'This product is already used in the hero slider.',
        ),
      );
      return;
    }

    next(error);
  }
});

router.put('/:id', async (request, response, next) => {
  try {
    const id = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    const input = slideSchema.parse(request.body);

    await checkProduct(input.productId);

    const [result] = await database.execute(
      `
        UPDATE hero_slides
        SET
          product_id = ?,
          title = ?,
          subtitle = ?,
          button_text = ?,
          display_order = ?,
          is_active = ?
        WHERE id = ?
      `,
      [
        input.productId,
        input.title,
        input.subtitle || null,
        input.buttonText,
        input.displayOrder,
        input.isActive,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      throw new HttpError(
        404,
        'Hero slide was not found.',
      );
    }

    response.json({
      success: true,
      message: 'Hero slide updated successfully.',
      data: await findSlide(id),
    });
  } catch (error) {
    if (error?.code === 'ER_DUP_ENTRY') {
      next(
        new HttpError(
          409,
          'This product is already used in the hero slider.',
        ),
      );
      return;
    }

    next(error);
  }
});

router.patch('/:id/status', async (request, response, next) => {
  try {
    const id = z.coerce
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
        UPDATE hero_slides
        SET is_active = ?
        WHERE id = ?
      `,
      [input.isActive, id],
    );

    if (result.affectedRows === 0) {
      throw new HttpError(
        404,
        'Hero slide was not found.',
      );
    }

    response.json({
      success: true,
      message: 'Hero slide status updated.',
      data: await findSlide(id),
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (request, response, next) => {
  try {
    const id = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    const [result] = await database.execute(
      `
        DELETE FROM hero_slides
        WHERE id = ?
      `,
      [id],
    );

    if (result.affectedRows === 0) {
      throw new HttpError(
        404,
        'Hero slide was not found.',
      );
    }

    response.json({
      success: true,
      message: 'Hero slide deleted successfully.',
    });
  } catch (error) {
    next(error);
  }
});

export default router;