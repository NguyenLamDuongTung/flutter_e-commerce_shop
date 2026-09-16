import crypto from 'node:crypto';

import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { authenticate } from '../middleware/authenticate.js';
import { HttpError } from '../utils/httpError.js';

const router = Router();

router.use(authenticate);

function createOrderNumber() {
  const date = new Date();
  const datePart = [
    date.getUTCFullYear(),
    String(date.getUTCMonth() + 1).padStart(2, '0'),
    String(date.getUTCDate()).padStart(2, '0'),
  ].join('');

  const randomPart = crypto
    .randomBytes(3)
    .toString('hex')
    .toUpperCase();

  return `FS-${datePart}-${randomPart}`;
}

function mapOrder(row) {
  return {
    id: row.id,
    orderNumber: row.order_number,
    customerName: row.customer_name,
    customerEmail: row.customer_email,
    customerPhone: row.customer_phone,
    shippingAddress: row.shipping_address,
    subtotal: Number(row.subtotal),
    shippingFee: Number(row.shipping_fee),
    totalAmount: Number(row.total_amount),
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    status: row.status,
    note: row.note,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function loadOrder(orderId, userId) {
  const [orderRows] = await database.execute(
    `
      SELECT *
      FROM orders
      WHERE id = ? AND user_id = ?
      LIMIT 1
    `,
    [orderId, userId],
  );

  if (orderRows.length === 0) {
    throw new HttpError(404, 'Order was not found.');
  }

  const [itemRows] = await database.execute(
    `
      SELECT
        id,
        product_id,
        product_name_snapshot,
        product_image_snapshot,
        price_snapshot,
        quantity,
        line_total
      FROM order_items
      WHERE order_id = ?
      ORDER BY id ASC
    `,
    [orderId],
  );

  return {
    ...mapOrder(orderRows[0]),
    items: itemRows.map((item) => ({
      id: item.id,
      productId: item.product_id,
      productName: item.product_name_snapshot,
      productImage: item.product_image_snapshot,
      price: Number(item.price_snapshot),
      quantity: Number(item.quantity),
      lineTotal: Number(item.line_total),
    })),
  };
}

router.post('/checkout', async (request, response, next) => {
  let connection;

  try {
    const input = z
      .object({
        customerName: z.string().trim().min(2).max(120),
        customerEmail: z
          .string()
          .trim()
          .toLowerCase()
          .email()
          .max(190),
        customerPhone: z.string().trim().min(8).max(30),
        shippingAddress: z.string().trim().min(10).max(500),
        paymentMethod: z
          .enum(['cod', 'bank_transfer'])
          .default('cod'),
        note: z.string().trim().max(1000).optional().default(''),
      })
      .parse(request.body);

    connection = await database.getConnection();
    await connection.beginTransaction();

    const [cartRows] = await connection.execute(
      `
        SELECT id
        FROM carts
        WHERE user_id = ?
        LIMIT 1
      `,
      [request.user.id],
    );

    if (cartRows.length === 0) {
      throw new HttpError(400, 'Your cart is empty.');
    }

    const cartId = cartRows[0].id;

    /*
      FOR UPDATE locks these products until checkout completes,
      preventing two customers from buying the final item at once.
    */
    const [cartItems] = await connection.execute(
      `
        SELECT
          ci.product_id,
          ci.quantity,
          p.name,
          p.price,
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
        FOR UPDATE
      `,
      [cartId],
    );

    if (cartItems.length === 0) {
      throw new HttpError(400, 'Your cart is empty.');
    }

    for (const item of cartItems) {
      if (!item.is_active) {
        throw new HttpError(
          400,
          `${item.name} is no longer available.`,
        );
      }

      if (Number(item.quantity) > Number(item.stock_quantity)) {
        throw new HttpError(
          400,
          `${item.name} only has ${item.stock_quantity} item(s) available.`,
        );
      }
    }

    const subtotal = cartItems.reduce(
      (total, item) =>
        total +
        Number(item.price) * Number(item.quantity),
      0,
    );

    const shippingFee = subtotal >= 10000000 ? 0 : 30000;
    const totalAmount = subtotal + shippingFee;
    const orderNumber = createOrderNumber();

    const [orderResult] = await connection.execute(
      `
        INSERT INTO orders (
          user_id,
          order_number,
          customer_name,
          customer_email,
          customer_phone,
          shipping_address,
          subtotal,
          shipping_fee,
          total_amount,
          payment_method,
          payment_status,
          status,
          note
        )
        VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending', ?
        )
      `,
      [
        request.user.id,
        orderNumber,
        input.customerName,
        input.customerEmail,
        input.customerPhone,
        input.shippingAddress,
        subtotal,
        shippingFee,
        totalAmount,
        input.paymentMethod,
        input.note || null,
      ],
    );

    for (const item of cartItems) {
      const price = Number(item.price);
      const quantity = Number(item.quantity);
      const lineTotal = price * quantity;

      await connection.execute(
        `
          INSERT INTO order_items (
            order_id,
            product_id,
            product_name_snapshot,
            product_image_snapshot,
            price_snapshot,
            quantity,
            line_total
          )
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `,
        [
          orderResult.insertId,
          item.product_id,
          item.name,
          item.image_url,
          price,
          quantity,
          lineTotal,
        ],
      );

      const [stockResult] = await connection.execute(
        `
          UPDATE products
          SET stock_quantity = stock_quantity - ?
          WHERE id = ?
            AND stock_quantity >= ?
            AND is_active = TRUE
        `,
        [
          quantity,
          item.product_id,
          quantity,
        ],
      );

      if (stockResult.affectedRows === 0) {
        throw new HttpError(
          409,
          `Stock for ${item.name} changed. Please try again.`,
        );
      }
    }

    await connection.execute(
      'DELETE FROM cart_items WHERE cart_id = ?',
      [cartId],
    );

    await connection.commit();

    response.status(201).json({
      success: true,
      message: 'Order placed successfully.',
      data: await loadOrder(
        orderResult.insertId,
        request.user.id,
      ),
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }

    next(error);
  } finally {
    connection?.release();
  }
});

router.get('/', async (request, response, next) => {
  try {
    const query = z
      .object({
        page: z.coerce.number().int().min(1).default(1),
        limit: z.coerce.number().int().min(1).max(50).default(10),
      })
      .parse(request.query);

    const offset = (query.page - 1) * query.limit;

    const [[countRow], [rows]] = await Promise.all([
      database.execute(
        `
          SELECT COUNT(*) AS total
          FROM orders
          WHERE user_id = ?
        `,
        [request.user.id],
      ),
      database.execute(
        `
          SELECT *
          FROM orders
          WHERE user_id = ?
          ORDER BY created_at DESC
          LIMIT ${Number(query.limit)}
          OFFSET ${Number(offset)}
        `,
        [request.user.id],
      ),
    ]);

    const totalItems = Number(countRow[0].total);

    response.json({
      success: true,
      data: {
        items: rows.map(mapOrder),
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
    const orderId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    response.json({
      success: true,
      data: await loadOrder(orderId, request.user.id),
    });
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/cancel', async (request, response, next) => {
  let connection;

  try {
    const orderId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    connection = await database.getConnection();
    await connection.beginTransaction();

    const [orderRows] = await connection.execute(
      `
        SELECT id, status
        FROM orders
        WHERE id = ? AND user_id = ?
        FOR UPDATE
      `,
      [orderId, request.user.id],
    );

    const order = orderRows[0];

    if (!order) {
      throw new HttpError(404, 'Order was not found.');
    }

    if (!['pending', 'confirmed'].includes(order.status)) {
      throw new HttpError(
        400,
        'This order can no longer be cancelled.',
      );
    }

    const [itemRows] = await connection.execute(
      `
        SELECT product_id, quantity
        FROM order_items
        WHERE order_id = ?
      `,
      [orderId],
    );

    for (const item of itemRows) {
      if (item.product_id !== null) {
        await connection.execute(
          `
            UPDATE products
            SET stock_quantity = stock_quantity + ?
            WHERE id = ?
          `,
          [item.quantity, item.product_id],
        );
      }
    }

    await connection.execute(
      `
        UPDATE orders
        SET status = 'cancelled'
        WHERE id = ?
      `,
      [orderId],
    );

    await connection.commit();

    response.json({
      success: true,
      message: 'Order cancelled successfully.',
      data: await loadOrder(orderId, request.user.id),
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }

    next(error);
  } finally {
    connection?.release();
  }
});

export default router;