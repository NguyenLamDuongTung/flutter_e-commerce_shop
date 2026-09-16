import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { authenticate } from '../middleware/authenticate.js';
import { authorizeAdmin } from '../middleware/authorizeAdmin.js';
import { HttpError } from '../utils/httpError.js';

const router = Router();

router.use(authenticate);
router.use(authorizeAdmin);

function mapOrder(row) {
  return {
    id: row.id,
    orderNumber: row.order_number,
    userId: row.user_id,
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

async function loadAdminOrder(
  orderId,
  connection = database,
) {
  const [orderRows] = await connection.execute(
    `
      SELECT *
      FROM orders
      WHERE id = ?
      LIMIT 1
    `,
    [orderId],
  );

  if (orderRows.length === 0) {
    throw new HttpError(404, 'Order was not found.');
  }

  const [itemRows] = await connection.execute(
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

/*
 * Dashboard
 */
router.get('/dashboard', async (request, response, next) => {
  try {
    const [
      [customerRows],
      [productRows],
      [orderRows],
      [revenueRows],
      [pendingRows],
      [lowStockRows],
      [recentOrders],
      [monthlySales],
    ] = await Promise.all([
      database.execute(`
        SELECT COUNT(*) AS total
        FROM users
        WHERE role = 'customer'
      `),

      database.execute(`
        SELECT COUNT(*) AS total
        FROM products
        WHERE is_active = TRUE
      `),

      database.execute(`
        SELECT COUNT(*) AS total
        FROM orders
      `),

      database.execute(`
        SELECT COALESCE(SUM(total_amount), 0) AS total
        FROM orders
        WHERE status = 'completed'
      `),

      database.execute(`
        SELECT COUNT(*) AS total
        FROM orders
        WHERE status IN ('pending', 'confirmed', 'processing')
      `),

      database.execute(`
        SELECT COUNT(*) AS total
        FROM products
        WHERE is_active = TRUE
          AND stock_quantity <= 5
      `),

      database.execute(`
        SELECT
          id,
          order_number,
          customer_name,
          total_amount,
          payment_status,
          status,
          created_at
        FROM orders
        ORDER BY created_at DESC
        LIMIT 8
      `),

      database.execute(`
        SELECT
          DATE_FORMAT(created_at, '%Y-%m') AS month_key,
          SUM(total_amount) AS revenue,
          COUNT(*) AS order_count
        FROM orders
        WHERE status = 'completed'
          AND created_at >= DATE_SUB(
            DATE_FORMAT(CURRENT_DATE, '%Y-%m-01'),
            INTERVAL 11 MONTH
          )
        GROUP BY DATE_FORMAT(created_at, '%Y-%m')
        ORDER BY month_key ASC
      `),
    ]);

    response.json({
      success: true,
      data: {
        statistics: {
          customers: Number(customerRows[0].total),
          products: Number(productRows[0].total),
          orders: Number(orderRows[0].total),
          revenue: Number(revenueRows[0].total),
          pendingOrders: Number(pendingRows[0].total),
          lowStockProducts: Number(lowStockRows[0].total),
        },

        recentOrders: recentOrders.map((order) => ({
          id: order.id,
          orderNumber: order.order_number,
          customerName: order.customer_name,
          totalAmount: Number(order.total_amount),
          paymentStatus: order.payment_status,
          status: order.status,
          createdAt: order.created_at,
        })),

        monthlySales: monthlySales.map((item) => ({
          month: item.month_key,
          revenue: Number(item.revenue),
          orderCount: Number(item.order_count),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
});

/*
 * Order management
 */
router.get('/orders', async (request, response, next) => {
  try {
    const query = z
      .object({
        page: z.coerce.number().int().min(1).default(1),
        limit: z.coerce
          .number()
          .int()
          .min(1)
          .max(100)
          .default(20),
        search: z.string().trim().max(100).optional().default(''),
        status: z
          .enum([
            'all',
            'pending',
            'confirmed',
            'processing',
            'shipping',
            'completed',
            'cancelled',
          ])
          .default('all'),
      })
      .parse(request.query);

    const conditions = ['1 = 1'];
    const parameters = [];

    if (query.search) {
      conditions.push(`
        (
          o.order_number LIKE ?
          OR o.customer_name LIKE ?
          OR o.customer_email LIKE ?
          OR o.customer_phone LIKE ?
        )
      `);

      const value = `%${query.search}%`;

      parameters.push(value, value, value, value);
    }

    if (query.status !== 'all') {
      conditions.push('o.status = ?');
      parameters.push(query.status);
    }

    const whereSql = conditions.join(' AND ');
    const offset = (query.page - 1) * query.limit;

    const [countRows] = await database.execute(
      `
        SELECT COUNT(*) AS total
        FROM orders o
        WHERE ${whereSql}
      `,
      parameters,
    );

    const [rows] = await database.execute(
      `
        SELECT o.*
        FROM orders o
        WHERE ${whereSql}
        ORDER BY o.created_at DESC
        LIMIT ${Number(query.limit)}
        OFFSET ${Number(offset)}
      `,
      parameters,
    );

    const totalItems = Number(countRows[0].total);

    response.json({
      success: true,
      data: {
        items: rows.map(mapOrder),
        pagination: {
          page: query.page,
          limit: query.limit,
          totalItems,
          totalPages: Math.ceil(
            totalItems / query.limit,
          ),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/orders/:id', async (request, response, next) => {
  try {
    const orderId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    response.json({
      success: true,
      data: await loadAdminOrder(orderId),
    });
  } catch (error) {
    next(error);
  }
});

router.patch(
  '/orders/:id/status',
  async (request, response, next) => {
    let connection;

    try {
      const orderId = z.coerce
        .number()
        .int()
        .positive()
        .parse(request.params.id);

      const input = z
        .object({
          status: z.enum([
            'pending',
            'confirmed',
            'processing',
            'shipping',
            'completed',
            'cancelled',
          ]),
          paymentStatus: z
            .enum([
              'pending',
              'paid',
              'failed',
              'refunded',
            ])
            .optional(),
        })
        .parse(request.body);

      connection = await database.getConnection();
      await connection.beginTransaction();

      const [orderRows] = await connection.execute(
        `
          SELECT id, status, payment_status
          FROM orders
          WHERE id = ?
          FOR UPDATE
        `,
        [orderId],
      );

      const order = orderRows[0];

      if (!order) {
        throw new HttpError(404, 'Order was not found.');
      }

      if (order.status === 'cancelled') {
        throw new HttpError(
          400,
          'A cancelled order cannot be reopened.',
        );
      }

      if (
        order.status === 'completed' &&
        input.status !== 'completed'
      ) {
        throw new HttpError(
          400,
          'A completed order cannot return to an earlier status.',
        );
      }

      if (
        input.status === 'cancelled' &&
        order.status !== 'cancelled'
      ) {
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
      }

      const paymentStatus =
        input.paymentStatus ??
        (input.status === 'completed'
          ? 'paid'
          : order.payment_status);

      await connection.execute(
        `
          UPDATE orders
          SET
            status = ?,
            payment_status = ?
          WHERE id = ?
        `,
        [
          input.status,
          paymentStatus,
          orderId,
        ],
      );

      await connection.commit();

      response.json({
        success: true,
        message: 'Order status updated successfully.',
        data: await loadAdminOrder(orderId),
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

/*
 * Customer management
 */
router.get('/customers', async (request, response, next) => {
  try {
    const query = z
      .object({
        page: z.coerce.number().int().min(1).default(1),
        limit: z.coerce
          .number()
          .int()
          .min(1)
          .max(100)
          .default(20),
        search: z.string().trim().max(100).optional().default(''),
      })
      .parse(request.query);

    const conditions = ["u.role = 'customer'"];
    const parameters = [];

    if (query.search) {
      conditions.push(`
        (
          u.full_name LIKE ?
          OR u.email LIKE ?
          OR u.phone LIKE ?
        )
      `);

      const value = `%${query.search}%`;
      parameters.push(value, value, value);
    }

    const whereSql = conditions.join(' AND ');
    const offset = (query.page - 1) * query.limit;

    const [countRows] = await database.execute(
      `
        SELECT COUNT(*) AS total
        FROM users u
        WHERE ${whereSql}
      `,
      parameters,
    );

    const [rows] = await database.execute(
      `
        SELECT
          u.id,
          u.full_name,
          u.email,
          u.phone,
          u.address,
          u.is_active,
          u.created_at,

          COUNT(DISTINCT o.id) AS order_count,

          COALESCE(
            SUM(
              CASE
                WHEN o.status = 'completed'
                THEN o.total_amount
                ELSE 0
              END
            ),
            0
          ) AS total_spent,

          COALESCE(
            (
              SELECT SUM(ci.quantity)
              FROM carts c
              JOIN cart_items ci ON ci.cart_id = c.id
              WHERE c.user_id = u.id
            ),
            0
          ) AS cart_item_count

        FROM users u
        LEFT JOIN orders o ON o.user_id = u.id
        WHERE ${whereSql}
        GROUP BY
          u.id,
          u.full_name,
          u.email,
          u.phone,
          u.address,
          u.is_active,
          u.created_at
        ORDER BY u.created_at DESC
        LIMIT ${Number(query.limit)}
        OFFSET ${Number(offset)}
      `,
      parameters,
    );

    const totalItems = Number(countRows[0].total);

    response.json({
      success: true,
      data: {
        items: rows.map((customer) => ({
          id: customer.id,
          fullName: customer.full_name,
          email: customer.email,
          phone: customer.phone,
          address: customer.address,
          isActive: Boolean(customer.is_active),
          orderCount: Number(customer.order_count),
          totalSpent: Number(customer.total_spent),
          cartItemCount: Number(
            customer.cart_item_count,
          ),
          createdAt: customer.created_at,
        })),

        pagination: {
          page: query.page,
          limit: query.limit,
          totalItems,
          totalPages: Math.ceil(
            totalItems / query.limit,
          ),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/customers/:id', async (request, response, next) => {
  try {
    const customerId = z.coerce
      .number()
      .int()
      .positive()
      .parse(request.params.id);

    const [customerRows] = await database.execute(
      `
        SELECT
          id,
          full_name,
          email,
          phone,
          address,
          is_active,
          created_at
        FROM users
        WHERE id = ? AND role = 'customer'
        LIMIT 1
      `,
      [customerId],
    );

    const customer = customerRows[0];

    if (!customer) {
      throw new HttpError(404, 'Customer was not found.');
    }

    const [cartRows] = await database.execute(
      `
        SELECT
          ci.product_id,
          p.name,
          p.slug,
          ci.quantity,
          p.price,
          (
            SELECT pi.image_url
            FROM product_images pi
            WHERE pi.product_id = p.id
            ORDER BY pi.is_primary DESC, pi.display_order ASC
            LIMIT 1
          ) AS image_url
        FROM carts c
        JOIN cart_items ci ON ci.cart_id = c.id
        JOIN products p ON p.id = ci.product_id
        WHERE c.user_id = ?
        ORDER BY ci.updated_at DESC
      `,
      [customerId],
    );

    const [orderRows] = await database.execute(
      `
        SELECT *
        FROM orders
        WHERE user_id = ?
        ORDER BY created_at DESC
      `,
      [customerId],
    );

    response.json({
      success: true,
      data: {
        customer: {
          id: customer.id,
          fullName: customer.full_name,
          email: customer.email,
          phone: customer.phone,
          address: customer.address,
          isActive: Boolean(customer.is_active),
          createdAt: customer.created_at,
        },

        currentCart: cartRows.map((item) => ({
          productId: item.product_id,
          name: item.name,
          slug: item.slug,
          quantity: Number(item.quantity),
          price: Number(item.price),
          lineTotal:
            Number(item.price) *
            Number(item.quantity),
          imageUrl: item.image_url,
        })),

        orderHistory: orderRows.map(mapOrder),
      },
    });
  } catch (error) {
    next(error);
  }
});

router.patch(
  '/customers/:id/status',
  async (request, response, next) => {
    try {
      const customerId = z.coerce
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
          UPDATE users
          SET is_active = ?
          WHERE id = ? AND role = 'customer'
        `,
        [
          input.isActive,
          customerId,
        ],
      );

      if (result.affectedRows === 0) {
        throw new HttpError(
          404,
          'Customer was not found.',
        );
      }

      response.json({
        success: true,
        message: input.isActive
          ? 'Customer account activated.'
          : 'Customer account disabled.',
      });
    } catch (error) {
      next(error);
    }
  },
);

/*
 * Sales report
 */
router.get('/sales', async (request, response, next) => {
  try {
    const query = z
      .object({
        year: z.coerce
          .number()
          .int()
          .min(2020)
          .max(2100)
          .default(new Date().getFullYear()),
      })
      .parse(request.query);

    const [monthlyRows] = await database.execute(
      `
        SELECT
          MONTH(created_at) AS month_number,
          COUNT(*) AS order_count,
          SUM(total_amount) AS revenue,
          AVG(total_amount) AS average_order_value
        FROM orders
        WHERE YEAR(created_at) = ?
          AND status = 'completed'
        GROUP BY MONTH(created_at)
        ORDER BY month_number ASC
      `,
      [query.year],
    );

    const monthlyMap = new Map(
      monthlyRows.map((row) => [
        Number(row.month_number),
        row,
      ]),
    );

    const months = Array.from(
      {
        length: 12,
      },
      (_, index) => {
        const month = index + 1;
        const row = monthlyMap.get(month);

        return {
          month,
          orderCount: Number(row?.order_count ?? 0),
          revenue: Number(row?.revenue ?? 0),
          averageOrderValue: Number(
            row?.average_order_value ?? 0,
          ),
        };
      },
    );

    const [topProducts] = await database.execute(
      `
        SELECT
          oi.product_id,
          oi.product_name_snapshot AS product_name,
          SUM(oi.quantity) AS quantity_sold,
          SUM(oi.line_total) AS revenue
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE YEAR(o.created_at) = ?
          AND o.status = 'completed'
        GROUP BY
          oi.product_id,
          oi.product_name_snapshot
        ORDER BY revenue DESC
        LIMIT 10
      `,
      [query.year],
    );

    response.json({
      success: true,
      data: {
        year: query.year,
        summary: {
          revenue: months.reduce(
            (total, item) => total + item.revenue,
            0,
          ),
          orderCount: months.reduce(
            (total, item) => total + item.orderCount,
            0,
          ),
        },
        months,
        topProducts: topProducts.map((product) => ({
          productId: product.product_id,
          productName: product.product_name,
          quantitySold: Number(product.quantity_sold),
          revenue: Number(product.revenue),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
});

export default router;