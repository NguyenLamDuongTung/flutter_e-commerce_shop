import { database } from '../config/database.js';
import { HttpError } from '../utils/httpError.js';
import { verifyAccessToken } from '../utils/jwt.js';

export async function authenticate(request, response, next) {
  try {
    const authorization = request.headers.authorization;

    if (!authorization?.startsWith('Bearer ')) {
      throw new HttpError(401, 'Authentication is required.');
    }

    const token = authorization.substring(7).trim();

    if (!token) {
      throw new HttpError(401, 'Authentication token is missing.');
    }

    let payload;

    try {
      payload = verifyAccessToken(token);
    } catch {
      throw new HttpError(
        401,
        'Authentication token is invalid or expired.',
      );
    }

    const [rows] = await database.execute(
      `
        SELECT
          id,
          full_name,
          email,
          phone,
          address,
          role,
          is_active,
          created_at,
          updated_at
        FROM users
        WHERE id = ?
        LIMIT 1
      `,
      [payload.sub],
    );

    const user = rows[0];

    if (!user || !user.is_active) {
      throw new HttpError(
        401,
        'This account does not exist or has been disabled.',
      );
    }

    request.user = user;
    next();
  } catch (error) {
    next(error);
  }
}