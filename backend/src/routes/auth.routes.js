import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { z } from 'zod';

import { database } from '../config/database.js';
import { authenticate } from '../middleware/authenticate.js';
import { HttpError } from '../utils/httpError.js';
import { createAccessToken } from '../utils/jwt.js';

const router = Router();

const registerSchema = z.object({
  fullName: z.string().trim().min(2).max(120),
  email: z.string().trim().toLowerCase().email().max(190),
  password: z.string().min(8).max(72),
  phone: z.string().trim().max(30).optional().default(''),
});

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1),
});

function publicUser(user) {
  return {
    id: user.id,
    fullName: user.full_name,
    email: user.email,
    phone: user.phone,
    address: user.address,
    role: user.role,
    createdAt: user.created_at,
  };
}

router.post('/register', async (request, response, next) => {
  let connection;

  try {
    const input = registerSchema.parse(request.body);

    const [existingUsers] = await database.execute(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [input.email],
    );

    if (existingUsers.length > 0) {
      throw new HttpError(
        409,
        'An account with this email already exists.',
      );
    }

    const passwordHash = await bcrypt.hash(input.password, 12);

    connection = await database.getConnection();
    await connection.beginTransaction();

    const [result] = await connection.execute(
      `
        INSERT INTO users (
          full_name,
          email,
          password_hash,
          phone,
          role
        )
        VALUES (?, ?, ?, ?, 'customer')
      `,
      [
        input.fullName,
        input.email,
        passwordHash,
        input.phone || null,
      ],
    );

    await connection.execute(
      'INSERT INTO carts (user_id) VALUES (?)',
      [result.insertId],
    );

    const [rows] = await connection.execute(
      `
        SELECT
          id,
          full_name,
          email,
          phone,
          address,
          role,
          created_at
        FROM users
        WHERE id = ?
      `,
      [result.insertId],
    );

    await connection.commit();

    const user = rows[0];
    const token = createAccessToken(user);

    response.status(201).json({
      success: true,
      message: 'Your account was created successfully.',
      data: {
        token,
        user: publicUser(user),
      },
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

router.post('/login', async (request, response, next) => {
  try {
    const input = loginSchema.parse(request.body);

    const [rows] = await database.execute(
      `
        SELECT
          id,
          full_name,
          email,
          password_hash,
          phone,
          address,
          role,
          is_active,
          created_at
        FROM users
        WHERE email = ?
        LIMIT 1
      `,
      [input.email],
    );

    const user = rows[0];

    if (!user) {
      throw new HttpError(401, 'Email or password is incorrect.');
    }

    if (!user.is_active) {
      throw new HttpError(403, 'This account has been disabled.');
    }

    const passwordMatches = await bcrypt.compare(
      input.password,
      user.password_hash,
    );

    if (!passwordMatches) {
      throw new HttpError(401, 'Email or password is incorrect.');
    }

    response.json({
      success: true,
      message: 'Login successful.',
      data: {
        token: createAccessToken(user),
        user: publicUser(user),
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/me', authenticate, async (request, response) => {
  response.json({
    success: true,
    data: {
      user: publicUser(request.user),
    },
  });
});

router.put('/profile', authenticate, async (request, response, next) => {
  try {
    const schema = z.object({
      fullName: z.string().trim().min(2).max(120),
      phone: z.string().trim().max(30).nullable().optional(),
      address: z.string().trim().max(500).nullable().optional(),
    });

    const input = schema.parse(request.body);

    await database.execute(
      `
        UPDATE users
        SET full_name = ?, phone = ?, address = ?
        WHERE id = ?
      `,
      [
        input.fullName,
        input.phone || null,
        input.address || null,
        request.user.id,
      ],
    );

    const [rows] = await database.execute(
      `
        SELECT
          id,
          full_name,
          email,
          phone,
          address,
          role,
          created_at
        FROM users
        WHERE id = ?
      `,
      [request.user.id],
    );

    response.json({
      success: true,
      message: 'Profile updated successfully.',
      data: {
        user: publicUser(rows[0]),
      },
    });
  } catch (error) {
    next(error);
  }
});

export default router;