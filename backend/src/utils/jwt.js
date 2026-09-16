import jwt from 'jsonwebtoken';

import { env } from '../config/env.js';

export function createAccessToken(user) {
  return jwt.sign(
    {
      sub: String(user.id),
      role: user.role,
      email: user.email,
    },
    env.jwtSecret,
    {
      expiresIn: env.jwtExpiresIn,
      issuer: 'flutter-shop-api',
      audience: 'flutter-shop-web',
    },
  );
}

export function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtSecret, {
    issuer: 'flutter-shop-api',
    audience: 'flutter-shop-web',
  });
}