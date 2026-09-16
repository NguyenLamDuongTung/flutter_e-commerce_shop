import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { authenticate } from '../middleware/authenticate.js';
import { HttpError } from '../utils/httpError.js';

const router = Router();

router.use(authenticate);

async function getOrCreateCart(userId, connection = database) {
  await connection.execute(
    `
      INSERT INTO carts (user_id)
      VALUES (?)
      ON DUPLICATE KEY UPDATE user_id = VALUES(user_id)
    `,
    [userId],
  );

  const [rows] = await connection.execute(
    `
      SELECT id
      FROM carts
      WHERE user_id = ?
      LIMIT 1
    `,
    [userId],
  );

  return rows[0].id;
}

async function loadCart(userId, connection = database) {
  const cartId = await getOrCreateCart(userId, connection);

  const [rows] = await connection.execute(
    `
      SELECT
        ci.id,
        ci.product_id,
        ci.quantity,
        ci.price_snapshot,
        p.name,
        p.slug,
        p.price AS current_price,
        p.stock_quantity,
        p.is_active,
        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          ORDER BY pi.is_primary DESC, pi.display_order ASC
          LIMIT 1
        ) AS image_url
      FROM cart_items ci
      JOIN products p ON p.id = ci.product_id
      WHERE ci.cart_id = ?
      ORDER BY ci.created_at DESC
    `,
    [cartId],
  );

  const items = rows.map((row) => {
    const price = Number(row.current_price);
    const quantity = Number(row.quantity);

    return {
      id: row.id,
      productId: row.product_id,
      name: row.name,
      slug: row.slug,
      imageUrl: row.image_url,
      price,
      previousPrice: Number(row.price_snapshot),
      quantity,
      stockQuantity: Number(row.stock_quantity),
      isAvailable:
        Boolean(row.is_active) &&
        Number(row.stock_quantity) >= quantity,
      lineTotal: price * quantity,
    };
  });

  return {
    id: cartId,
    items,
    itemCount: items.reduce(
      (total, item) => total + item.quantity,
      0,
    ),
    subtotal: items.reduce(
      (total, item) => total + item.lineTotal,
      0,
    ),
  };
}

router.get('/', async (request, response, next) => {
  try {
    response.json({
      success: true,
      data: await loadCart(request.user.id),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/items', async (request, response, next) => {
  try {
    const input = z
      .object({
        productId: z.coerce.number().int().positive(),
        quantity: z.coerce.number().int().min(1).max(99).default(1),
      })
      .parse(request.body);

    const [productRows] = await database.execute(
      `
        SELECT id, price, stock_quantity, is_active
        FROM products
        WHERE id = ?
        LIMIT 1
      `,
      [input.productId],
    );

    const product = productRows[0];

    if (!product || !product.is_active) {
      throw new HttpError(
        404,
        'This product is no longer available.',
      );
    }

    const cartId = await getOrCreateCart(request.user.id);

    const [existingRows] = await database.execute(
      `
        SELECT quantity
        FROM cart_items
        WHERE cart_id = ? AND product_id = ?
        LIMIT 1
      `,
      [cartId, input.productId],
    );

    const resultingQuantity =
      Number(existingRows[0]?.quantity ?? 0) +
      input.quantity;

    if (resultingQuantity > Number(product.stock_quantity)) {
      throw new HttpError(
        400,
        `Only ${product.stock_quantity} item(s) are available.`,
      );
    }

    await database.execute(
      `
        INSERT INTO cart_items (
          cart_id,
          product_id,
          quantity,
          price_snapshot
        )
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          quantity = quantity + VALUES(quantity),
          price_snapshot = VALUES(price_snapshot),
          updated_at = CURRENT_TIMESTAMP
      `,
      [
        cartId,
        input.productId,
        input.quantity,
        product.price,
      ],
    );

    response.status(201).json({
      success: true,
      message: 'Product added to cart.',
      data: await loadCart(request.user.id),
    });
  } catch (error) {
    next(error);
  }
});

router.put('/items/:productId', async (request, response, next) => {
  try {
    const productId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.productId);

    const input = z
      .object({
        quantity: z.coerce.number().int().min(1).max(99),
      })
      .parse(request.body);

    const cartId = await getOrCreateCart(request.user.id);

    const [productRows] = await database.execute(
      `
        SELECT price, stock_quantity, is_active
        FROM products
        WHERE id = ?
        LIMIT 1
      `,
      [productId],
    );

    const product = productRows[0];

    if (!product || !product.is_active) {
      throw new HttpError(
        404,
        'This product is no longer available.',
      );
    }

    if (input.quantity > Number(product.stock_quantity)) {
      throw new HttpError(
        400,
        `Only ${product.stock_quantity} item(s) are available.`,
      );
    }

    const [result] = await database.execute(
      `
        UPDATE cart_items
        SET
          quantity = ?,
          price_snapshot = ?,
          updated_at = CURRENT_TIMESTAMP
        WHERE cart_id = ? AND product_id = ?
      `,
      [
        input.quantity,
        product.price,
        cartId,
        productId,
      ],
    );

    if (result.affectedRows === 0) {
      throw new HttpError(
        404,
        'This product is not in your cart.',
      );
    }

    response.json({
      success: true,
      message: 'Cart updated.',
      data: await loadCart(request.user.id),
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/items/:productId', async (request, response, next) => {
  try {
    const productId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.productId);

    const cartId = await getOrCreateCart(request.user.id);

    await database.execute(
      `
        DELETE FROM cart_items
        WHERE cart_id = ? AND product_id = ?
      `,
      [cartId, productId],
    );

    response.json({
      success: true,
      message: 'Product removed from cart.',
      data: await loadCart(request.user.id),
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/', async (request, response, next) => {
  try {
    const cartId = await getOrCreateCart(request.user.id);

    await database.execute(
      'DELETE FROM cart_items WHERE cart_id = ?',
      [cartId],
    );

    response.json({
      success: true,
      message: 'Cart cleared.',
      data: await loadCart(request.user.id),
    });
  } catch (error) {
    next(error);
  }
});

export default router;