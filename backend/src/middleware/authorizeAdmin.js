import { HttpError } from '../utils/httpError.js';

export function authorizeAdmin(request, response, next) {
  if (!request.user) {
    return next(new HttpError(401, 'Authentication is required.'));
  }

  if (request.user.role !== 'admin') {
    return next(
      new HttpError(
        403,
        'You do not have permission to access the admin system.',
      ),
    );
  }

  next();
}